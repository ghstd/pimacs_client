require 'gosu'
require 'json'
require 'set'
require 'singleton'

$TILE_SIZE = 32

require_relative 'classes/world'
require_relative 'classes/map'
require_relative 'classes/interface'
require_relative 'classes/pointer'
require_relative 'classes/basic_abilities/index'
require_relative 'classes/player'
require_relative 'classes/monster'
require_relative 'classes/projectile'
require_relative 'modules/pathfinder'
require_relative 'modules/pixels_converter'
require_relative 'modules/dev_instruments'

class App < Gosu::Window
  WINDOW_WIDTH = 640
  WINDOW_HEIGHT = 480
  HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2
  HALF_WINDOW_HEIGHT = WINDOW_HEIGHT / 2
  TILE_SIZE = $TILE_SIZE
  HALF_TILE_SIZE = TILE_SIZE / 2
  INTERFACE_SIZE_WIDTH = 220
  INTERFACE_SIZE_HEIGHT = 120
  HALF_INTERFACE_SIZE_WIDTH = INTERFACE_SIZE_WIDTH / 2
  HALF_INTERFACE_SIZE_HEIGHT = INTERFACE_SIZE_HEIGHT / 2
  INTERFACE_COLOR = Gosu::Color.new(255, 22, 35, 46)

  def initialize
    super(WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT)
    self.caption = "Tiled Map Test"

    @world = World.instance

    @player = Player.new(160, 160)

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
  end

  def change_map(map_name)
    @world.change_map(map_name)
    @player.moving_component.stop_moving
  end

  def update_camera_position(map_width, map_height)
    camera_x = [@player.moving_component.x - HALF_WINDOW_WIDTH, 0].max
    camera_y = [@player.moving_component.y - HALF_WINDOW_HEIGHT, 0].max

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

      @player.moving_component.start_moving(target_tile_x, target_tile_y,)
      @player.animating_component.set_sprite_direction(target_x)

      @pointer.init_click_animation(target_x, target_y)

    elsif id == Gosu::KB_Q # KB_Q

      @player.animating_component.spelling = true
      @player.create_projectile(x, y,camera_position_x, camera_position_y)

    elsif id == Gosu::MS_RIGHT # MS_RIGHT

      monster = @monsters.find do |monster|
        ((monster.monster_x / TILE_SIZE).to_i == target_tile_x) && ((monster.monster_y / TILE_SIZE).to_i == target_tile_y)
      end
      if monster
        @player.player_target = monster
      else
        @player.player_target = [target_tile_x, target_tile_y]
      end

    elsif id == Gosu::KB_ESCAPE # KB_ESCAPE

      @player.player_target = nil

    end
  end

  def update
    # Сброс флага после первого кадра
    @first_frame = false if @first_frame

    @player.update
    update_camera_position(@world.current_map.width, @world.current_map.height) unless @first_frame

    @world.current_map.transition_areas.each do |area|
      if @player.player_in_area?(area)

        @player.player_target = nil
        @player.moving_component.x = area[:destination][:x] + rand(0..(area[:destination][:width] / TILE_SIZE - 1)) * TILE_SIZE
        @player.moving_component.y = area[:destination][:y] + rand(0..(area[:destination][:height] / TILE_SIZE - 1)) * TILE_SIZE
        change_map(area[:to_map])
        break
      end
    end

    @world.current_map.monsters.each do |monster|
      monster.update
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

        DevInstruments.draw_grid(@world.current_map.width, @world.current_map.height, TILE_SIZE)
        @pointer.draw_pointer_rect(camera_x, camera_y)
        @pointer.draw_pointer_click

        @player.draw
        @world.current_map.monsters.each do |monster|
          monster.draw
        end
      end
    end

    # Отрисовка интерфейса
    @interface.draw_interface

    # '========================='
    @player.draw_target_xp_bar
    @player.draw_xp_mp_bars
  end

end

app = App.new
app.show
