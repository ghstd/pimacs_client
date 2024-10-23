require 'gosu'
require 'json'
require 'set'
require 'singleton'
require 'securerandom'

$TILE_SIZE = 32

require_relative 'classes/world'
require_relative 'classes/map'
require_relative 'classes/interface'
require_relative 'classes/pointer'
require_relative 'classes/individual_abilities/index'
require_relative 'classes/skills/index'
require_relative 'classes/player'
require_relative 'classes/monsters/index'
require_relative 'modules/pathfinder'
require_relative 'modules/pixels_converter'
require_relative 'modules/timeouts_registrator'
require_relative 'modules/id_generator'
require_relative 'modules/dev_instruments'

require 'websocket-client-simple'
require 'json'
require_relative 'websocket_client'

class App < Gosu::Window
  # WINDOW_WIDTH = 640
  # WINDOW_HEIGHT = 480
  WINDOW_WIDTH = 760
  WINDOW_HEIGHT = 540
  HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2
  HALF_WINDOW_HEIGHT = WINDOW_HEIGHT / 2
  TILE_SIZE = $TILE_SIZE
  HALF_TILE_SIZE = TILE_SIZE / 2
  INTERFACE_SIZE_WIDTH = 220
  INTERFACE_SIZE_HEIGHT = 120
  HALF_INTERFACE_SIZE_WIDTH = INTERFACE_SIZE_WIDTH / 2
  HALF_INTERFACE_SIZE_HEIGHT = INTERFACE_SIZE_HEIGHT / 2
  INTERFACE_COLOR = Gosu::Color.new(255, 22, 35, 46)

  attr_accessor :timestamp

  def initialize
    super(WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT)
    self.caption = "Tiled Map Test"

    @world = World.instance

    @player = Player.new(192, 192)

    @world.current_map.players.add(@player)

    @interface = Interface.new(
      window_width: WINDOW_WIDTH,
      window_height: WINDOW_HEIGHT,
      interface_width: INTERFACE_SIZE_WIDTH,
      interface_height: INTERFACE_SIZE_HEIGHT,
      color: INTERFACE_COLOR
    )

    @pointer = Pointer.new(
      correction_x: HALF_INTERFACE_SIZE_WIDTH,
      correction_y: HALF_INTERFACE_SIZE_HEIGHT,
      window: self
    )

    # Флаг для проверки первого кадра
    @first_frame = true

    # '========================='
    WebSocketClient.instance.connect

    @timestamp = Time.now
  end

  def change_map(map_name)
    @world.change_map(map_name)
  end

  def update_camera_position(map_width, map_height)
    camera_x = [@player.x - HALF_WINDOW_WIDTH, 0].max
    camera_y = [@player.y - HALF_WINDOW_HEIGHT, 0].max

    map_width_px = map_width * TILE_SIZE
    map_height_px = map_height * TILE_SIZE

    if map_width_px < WINDOW_WIDTH
      camera_x = -(WINDOW_WIDTH - map_width_px) / 2
    else
      camera_x = [camera_x, map_width_px - WINDOW_WIDTH].min
    end

    if map_height_px < WINDOW_HEIGHT
      camera_y = -(WINDOW_HEIGHT - map_height_px) / 2
    else
      camera_y = [camera_y, map_height_px - WINDOW_HEIGHT].min
    end

    return camera_x, camera_y
  end

  def button_down(id)
    x, y = @pointer.current_position
    camera_position_x, camera_position_y = update_camera_position(@world.current_map.width, @world.current_map.height)

    target_x = ((x + camera_position_x) / TILE_SIZE).to_i * TILE_SIZE
    target_y = ((y + camera_position_y) / TILE_SIZE).to_i * TILE_SIZE

    target_tile_x = ((x + camera_position_x) / TILE_SIZE).to_i
    target_tile_y = ((y + camera_position_y) / TILE_SIZE).to_i

    if id == Gosu::MS_LEFT # MS_LEFT

      @player.start_moving(target_tile_x, target_tile_y)

      @pointer.init_click_animation(target_x, target_y)

      # '========================='
      WebSocketClient.instance.player_move(target_tile_x, target_tile_y)

    elsif id == Gosu::KB_Q # KB_Q

      @player.skills[Skills::RedBall].use_skill

    elsif id == Gosu::MS_RIGHT # MS_RIGHT

      monster = @world.current_map.monsters.find do |monster|
        (((monster.x + HALF_TILE_SIZE) / TILE_SIZE).to_i == target_tile_x) && (((monster.y + HALF_TILE_SIZE) / TILE_SIZE).to_i == target_tile_y)
      end
      if monster
        @player.target = monster
      else
        @player.target = [target_tile_x, target_tile_y]
      end

    elsif id == Gosu::KB_ESCAPE # KB_ESCAPE

      @player.target = nil

    end
  end

  def update
    # @timestamp = (Time.now.to_f * 1000).to_i
    # p Gosu.fps

    # Сброс флага после первого кадра
    @first_frame = false if @first_frame

    @player.update
    update_camera_position(@world.current_map.width, @world.current_map.height) unless @first_frame

    @world.current_map.transition_areas.each do |area|
      if @player.player_in_area?(area)

        old_map_name = @world.current_map_name
        @player.target = nil
        @player.stop_moving
        @world.current_map.players.delete(@player)
        @player.x = area[:destination][:x] + rand(0..(area[:destination][:width] / TILE_SIZE - 1)) * TILE_SIZE
        @player.y = area[:destination][:y] + rand(0..(area[:destination][:height] / TILE_SIZE - 1)) * TILE_SIZE
        change_map(area[:to_map])
        @world.current_map.players.add(@player)
        new_map_name = @world.current_map_name

        WebSocketClient.instance.player_change_map(
          player_id: @player.id,
          player_x: @player.x,
          player_y: @player.y,
          old_map_name: old_map_name,
          new_map_name: new_map_name
        )
        break
      end
    end

    @world.current_map.monsters.each do |monster|
      monster.update
    end
    @world.current_map.projectiles.each do |projectile|
      projectile.update
    end
    TimeoutsRegistrator.update
    # p TimeoutsRegistrator.info
  end

  def update_maps_data
    # message = WebSocketClient.instance.read_message
    # @data = message if message

    data = WebSocketClient.instance.read_message
    return unless data

    data && data.each do |map_name, new_state|
    # @data && @data.each do |map_name, new_state|
      current_players = @world.maps[map_name].get_players_hash
      current_projectiles = @world.maps[map_name].get_projectiles_hash
      current_monsters = @world.maps[map_name].get_monsters_hash

      new_state['players'].each do |player|
        if current_player = current_players[player['id']]
          current_player.server_x = player['x']
          current_player.server_y = player['y']
        end
        # Gosu.draw_rect(player['x'], player['y'], 32, 32, Gosu::Color::GREEN) # to delete
      end

      new_state['projectiles'].each do |projectile|
        if current_projectile = current_projectiles[projectile['id']]
          current_projectile.x = projectile['x']
          current_projectile.y = projectile['y']
        else
          new_projectile = Object.const_get("Projectiles::#{projectile['type']}").new(
            owner: @world.find_creature_by_id(projectile['owner_id']),
            target: @world.find_creature_by_id(projectile['target_id']),
            start_x: projectile['x'],
            start_y: projectile['y'],
            target_x: projectile['target_x'],
            target_y: projectile['target_y'],
            speed: projectile['speed'],
            size: projectile['size'],
            id: projectile['id'],
            projectile_animation: Object.const_get("ProjectileAnimations::#{projectile['type']}"),
            on_target_animation: OnTargetAnimations::RedBall
          )
          @world.maps[map_name].projectiles << new_projectile
        end
        # Gosu.draw_rect(projectile['x'] - 4, projectile['y'] - 4, 8, 8, Gosu::Color::BLUE) # to delete
      end

      new_state['monsters'].each do |monster|
        if current_monster = current_monsters[monster['id']]
          current_monster.server_x = monster['x']
          current_monster.server_y = monster['y']
          current_monster.spelling = monster['spelling']
          current_monster.in_action = monster['in_action']
          current_monster.moving = monster['moving']
          current_monster.new_path = monster['new_path']
          current_monster.final_goal = monster['final_goal']
          current_monster.target_of_movement_x = monster['target_of_movement_x']
          current_monster.target_of_movement_y = monster['target_of_movement_y']
        else
          new_monster = Object.const_get(monster['monster_type']).new(
            x: monster['x'],
            y: monster['y'],
            id: monster['id']
          )
          new_monster.server_x = monster['x']
          new_monster.server_y = monster['y']
          new_monster.spelling = monster['spelling']
          new_monster.moving = monster['moving']
          new_monster.new_path = monster['new_path']
          new_monster.final_goal = monster['final_goal']
          new_monster.target_of_movement_x = monster['target_of_movement_x']
          new_monster.target_of_movement_y = monster['target_of_movement_y']

          @world.maps[map_name].monsters << new_monster
        end
        # Gosu.draw_rect(monster['x'], monster['y'], 32, 32, Gosu::Color::RED) # to delete
      end

    end
  end

  def draw
    camera_x, camera_y = update_camera_position(@world.current_map.width, @world.current_map.height)

    Gosu.translate(HALF_INTERFACE_SIZE_WIDTH, HALF_INTERFACE_SIZE_HEIGHT) do
      Gosu.translate(-camera_x, -camera_y) do

        @world.current_map.tile_layers.each do |layer|
          layer['data'].each_with_index do |tile_id, index|
            next if tile_id == 0

            x = (index % @world.current_map.width) * TILE_SIZE
            y = (index / @world.current_map.width) * TILE_SIZE

            @world.tiles[tile_id - 1].draw(x, y, 0)
          end
        end

        # DevInstruments.draw_grid(@world.current_map.width, @world.current_map.height, TILE_SIZE)
        @pointer.draw_pointer_rect(camera_x, camera_y)
        @pointer.draw_pointer_click

        @player.draw
        @world.current_map.monsters.each do |monster|
          monster.draw
        end
        @world.current_map.projectiles.each do |projectile|
          projectile.draw
        end
        @world.current_map.animations.each do |animation|
          animation.draw
        end

        # '========================='
        update_maps_data
        # '========================='
      end
    end

    @interface.draw_interface

    # '========================='
    @player.draw_target_xp_bar
    @player.draw_xp_mp_bars
  end

end

app = App.new
app.show
