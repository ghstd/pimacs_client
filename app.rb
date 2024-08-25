require 'gosu'
require 'json'
require 'set'

require_relative 'modules/dev_instruments'
require_relative 'modules/pathfinder'
require_relative 'modules/pixels_converter'
require_relative 'classes/map_loader'
require_relative 'classes/interface'
require_relative 'classes/pointer'
require_relative 'classes/live_creature'
require_relative 'classes/player'
require_relative 'classes/monster'

class App < Gosu::Window
  # Константы для размеров окна и тайлов
  WINDOW_WIDTH = 640
  WINDOW_HEIGHT = 480
  HALF_WINDOW_WIDTH = WINDOW_WIDTH / 2
  HALF_WINDOW_HEIGHT = WINDOW_HEIGHT / 2
  TILE_SIZE = 32
  HALF_TILE_SIZE = TILE_SIZE / 2
  INTERFACE_SIZE_WIDTH = 220
  INTERFACE_SIZE_HEIGHT = 120
  HALF_INTERFACE_SIZE_WIDTH = INTERFACE_SIZE_WIDTH / 2
  HALF_INTERFACE_SIZE_HEIGHT = INTERFACE_SIZE_HEIGHT / 2
  INTERFACE_COLOR = Gosu::Color.new(255, 22, 35, 46)

  def initialize
    super(WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT)
    self.caption = "Tiled Map Test"

    @map_loader = MapLoader.new(maps_pathes: ['maps/3.json', 'maps/4.json', 'maps/5.json'])
    load_map('4')

    @player = Player.new(
      tile_size: TILE_SIZE,
      all_tiles_info: @map_loader.all_tiles_info,
      map_width: @map_loader.map_width,
      map_height: @map_loader.map_height,
      map_loader: @map_loader
    )
    @map_loader.players.add(@player)

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

    # Загружаем изображения тайлов
    @tileset_image_base = Gosu::Image.new('assets/base.png')
    @tileset_image_water = Gosu::Image.new('assets/water.png')
    # Создаем массив для хранения картинок каждого тайла
    @tiles_base = Gosu::Image.load_tiles(@tileset_image_base, TILE_SIZE, TILE_SIZE)
    @tiles_water = Gosu::Image.load_tiles(@tileset_image_water, TILE_SIZE, TILE_SIZE)
    @tiles = @tiles_base + @tiles_water

    # Флаг для проверки первого кадра
    @first_frame = true
  end

  def load_map(map_name)
    @map_loader.load_map(map_name)
    @player && @player.stop_moving
    @player && @player.all_tiles_info = @map_loader.all_tiles_info
    @player && @player.map_width = @map_loader.map_width
    @player && @player.map_height = @map_loader.map_height
    @player && @player.map_loader = @map_loader

    '=========================='
    @monsters = []

    if map_name == '5'
      3.times do
        monster = Monster.new(
          tile_size: TILE_SIZE,
          map_width: @map_loader.map_width,
          map_height: @map_loader.map_height,
          all_tiles_info: @map_loader.all_tiles_info
        )
        @map_loader.monsters.add(monster)
        @monsters << monster
      end
    end
  end

  def update_camera_position(map_width, map_height)
    camera_x = [@player.player_x - HALF_WINDOW_WIDTH, 0].max
    camera_y = [@player.player_y - HALF_WINDOW_HEIGHT, 0].max

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
    camera_position_x, camera_position_y = update_camera_position(@map_loader.map_width, @map_loader.map_height)

    target_x = ((x + camera_position_x) / TILE_SIZE).to_i * TILE_SIZE
    target_y = ((y + camera_position_y) / TILE_SIZE).to_i * TILE_SIZE

    target_tile_x = ((x + camera_position_x) / TILE_SIZE).to_i
    target_tile_y = ((y + camera_position_y) / TILE_SIZE).to_i

    if id == Gosu::MS_LEFT # MS_LEFT

      # start_tile_x = (@player.player_x / TILE_SIZE).to_i
      # start_tile_y = (@player.player_y / TILE_SIZE).to_i

      # path = Pathfinder.find_path(
      #   start_x: start_tile_x,
      #   start_y: start_tile_y,
      #   goal_x: target_tile_x,
      #   goal_y: target_tile_y,
      #   map_width: @map_loader.map_width,
      #   map_height: @map_loader.map_height,
      #   all_tiles_info: @map_loader.all_tiles_info
      # )

      @player.start_moving(target_tile_x, target_tile_y, @map_loader.map_width, @map_loader.map_height)
      # @player.start_moving(path)
      @player.set_sprite_direction(target_x, target_y)

      @pointer.init_click_animation(target_x, target_y, TILE_SIZE)

    elsif id == Gosu::KB_Q # KB_Q

      @player.player_spelling = true
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

    @player.update(@map_loader.map_width, @map_loader.map_height)
    # @player.update
    # @player.move_player_with_mouse(@map_loader.map_width, @map_loader.map_height)
    update_camera_position(@map_loader.map_width, @map_loader.map_height) unless @first_frame

    @map_loader.transition_areas.each do |area|
      if @player.player_in_area?(area)
        @player.player_target = nil
        @player.player_x = area[:destination_data][:x] + rand(0..(area[:destination_data][:width] / TILE_SIZE - 1)) * TILE_SIZE
        @player.player_y = area[:destination_data][:y] + rand(0..(area[:destination_data][:height] / TILE_SIZE - 1)) * TILE_SIZE
        load_map(area[:destination])
        break
      end
    end

    # '========================='
    if !@monsters.empty?
      to_delete = []
      @monsters.each do |monster|
        monster.xp <= 0 ? to_delete << monster : monster.update
      end
      to_delete.each {|monster| @monsters.delete(monster)}
    end
  end

  def draw
    camera_x, camera_y = update_camera_position(@map_loader.map_width, @map_loader.map_height)

    Gosu.translate(HALF_INTERFACE_SIZE_WIDTH, HALF_INTERFACE_SIZE_HEIGHT) do
      Gosu.translate(-camera_x, -camera_y) do

        @map_loader.map['layers'].each do |layer|
          next unless layer['type'] == 'tilelayer'

          layer['data'].each_with_index do |tile_id, index|
            next if tile_id == 0

            x = (index % @map_loader.map_width) * TILE_SIZE
            y = (index / @map_loader.map_width) * TILE_SIZE
            @tiles[tile_id - 1].draw(x, y, 0)
          end
        end

        DevInstruments.draw_grid(@map_loader.map_width, @map_loader.map_height, TILE_SIZE)
        @pointer.draw_pointer_rect(camera_x, camera_y, TILE_SIZE)
        @pointer.draw_pointer_click

        @player.draw

        # '========================='
        if !@monsters.empty?
          @monsters.each {|monster| monster.draw}
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
