require 'gosu'
require 'json'
require 'set'

require_relative 'projectile'

class GameWindow < Gosu::Window
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
  # INTERFACE_COLOR = Gosu::Color.new(255, 24, 38, 37)
  INTERFACE_COLOR = Gosu::Color.new(255, 22, 35, 46)

  def initialize
    super(WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT)
    self.caption = "Tiled Map Test"

    # Добавляем игрока
    @sprites_right = Gosu::Image.load_tiles('assets/wizard_right.png', 32, 32)
    @sprites_left = Gosu::Image.load_tiles('assets/wizard_left.png', 32, 32)
    @player_spell = Gosu::Image.new('assets/wizard_spell.png')
    @current_frame = 0
    @player_image = nil
    @direction = :right
    @frame_delay = 10 # Количество кадров, которые должны пройти, прежде чем сменится спрайт
    @frame_counter = 0
    @player_spelling = false
    @spelling_delay = 20
    @spelling_counter = 0

    # @player_image = Gosu::Image.new('assets/player.png')
    @player_x = 160
    @player_y = 160
    @player_speed = 2
    @player_width = 32
    @player_height = 32

    @projectiles = []
    @projectiles_target = nil
    @pointer_click_animations = []

    @adjusted_mouse_x = mouse_x - HALF_INTERFACE_SIZE_WIDTH
    @adjusted_mouse_y = mouse_y - HALF_INTERFACE_SIZE_HEIGHT

    # Флаг для проверки первого кадра
    @first_frame = true

    # Загружаем карты
    @map_3 = JSON.parse(File.read('3.json'))
    @map_4 = JSON.parse(File.read('4.json'))

    # Загружаем карту
    load_map(@map_3)

    # Загружаем изображения тайлов
    @tileset_image_base = Gosu::Image.new('assets/base.png')
    @tileset_image_water = Gosu::Image.new('assets/water.png')

    # Создаем массив для хранения картинок каждого тайла
    @tiles_base = Gosu::Image.load_tiles(@tileset_image_base, TILE_SIZE, TILE_SIZE)
    @tiles_water = Gosu::Image.load_tiles(@tileset_image_water, TILE_SIZE, TILE_SIZE)
    @tiles = @tiles_base + @tiles_water
  end

  def load_map(map)
    @map = map
    @moving = false
    # Набор тайлов всех слоев карты
    @tiles_info = []

    @map['layers'].each do |layer|
      next if layer['type'] != 'tilelayer'
      layer['data'].each_with_index do |tile_id, index|
        @map['tilesets'].each do |tileset|
          next if !(tileset['firstgid']..tileset['tilecount']).cover?(tile_id)
          tile = tileset['tiles'].find { |tile| tile['id'] == (tile_id - 1) }
          next unless tile
          if @tiles_info[index].nil?
            @tiles_info[index] = [tile]
          else
            @tiles_info[index] << tile
          end
        end
      end
    end

    # Получаем объекты перемещений
    @transition_areas = []

    @map['layers'].each do |layer|
      if layer['type'] == 'objectgroup' && layer['name'] == 'Transition'
        layer['objects'].each do |object|
          @transition_areas << {
            x: object['x'],
            y: object['y'],
            width: object['width'],
            height: object['height'],
            destination: object['properties'].find { |prop| prop['name'] == 'to' }['value']
          }
        end
      end
    end

    # Получаем объекты столкновений
    @collidable_tiles = []

    @map['tilesets'].each do |tileset|
      tileset['tiles']&.each do |tile|
        if tile['properties']
          collides_property = tile['properties'].find { |prop| prop['name'] == 'collides' }
          if collides_property && collides_property['value'] == true
            @collidable_tiles << tile['id']
          end
        end
      end
    end

    # Установка камеры на игроке при загрузке карты
    update_camera_position unless @first_frame
  end

  def move_player_with_buttons
    move_x, move_y = 0, 0

    move_x -= @player_speed if Gosu.button_down?(Gosu::KB_LEFT)
    move_x += @player_speed if Gosu.button_down?(Gosu::KB_RIGHT)
    move_y -= @player_speed if Gosu.button_down?(Gosu::KB_UP)
    move_y += @player_speed if Gosu.button_down?(Gosu::KB_DOWN)

    # Создаем прямоугольник игрока с его предполагаемой новой позицией
    player_rect = {
      x: @player_x + move_x,
      y: @player_y + move_y,
      width: @player_width,
      height: @player_height
    }

    # Проверяем, может ли игрок переместиться в новую позицию
    if can_move_to?(player_rect)
      @player_x += move_x
      @player_y += move_y
    end

    # Ограничиваем движение игрока рамками карты
    @player_x = [[@player_x, 0].max, @map['width'] * TILE_SIZE - @player_width].min
    @player_y = [[@player_y, 0].max, @map['height'] * TILE_SIZE - @player_height].min
  end

  def can_move_to?(player_rect)
    tile_x_start = (player_rect[:x] / TILE_SIZE).to_i
    tile_x_end = ((player_rect[:x] + player_rect[:width] - 1) / TILE_SIZE).to_i
    tile_y_start = (player_rect[:y] / TILE_SIZE).to_i
    tile_y_end = ((player_rect[:y] + player_rect[:height] - 1) / TILE_SIZE).to_i

    (tile_x_start..tile_x_end).each do |tile_x|
      (tile_y_start..tile_y_end).each do |tile_y|
        tile_index = tile_x + tile_y * @map['width']

        # Корректный способ получения текущего tile_id
        @map['layers'].each do |layer|
          current_tile_id = nil
          next unless layer['type'] == 'tilelayer'
          current_tile_id = layer['data'][tile_index]
          next if current_tile_id.nil?
          current_tile_id -= 1
          next if current_tile_id < 0

          if @collidable_tiles.include?(current_tile_id)
            # Проверка наличия объектов коллизий в тайле
            tileset = @map['tilesets'].find { |t| (t['firstgid'] <= current_tile_id + 1) && (current_tile_id + 1 <= t['tilecount']) }
            tile_data = tileset['tiles'].find { |t| t['id'] == current_tile_id }

            if tile_data && tile_data['objectgroup']
              tile_data['objectgroup']['objects'].each do |obj|
                if collides_with_object?(player_rect, tile_x, tile_y, obj)
                  # p 'collides with object'
                  return false
                end
              end
            else
              # p 'collides with tile'
              return false
            end
          else
            next
          end
        end
      end
    end

    true
  end

  def collides_with_object?(player_rect, tile_x, tile_y, obj)
    obj_rect = {
      x: tile_x * TILE_SIZE + obj['x'],
      y: tile_y * TILE_SIZE + obj['y'],
      width: obj['width'],
      height: obj['height']
    }

    # Проверка пересечения прямоугольников
    return false if player_rect[:x] + player_rect[:width] <= obj_rect[:x]
    return false if player_rect[:x] >= obj_rect[:x] + obj_rect[:width]
    return false if player_rect[:y] + player_rect[:height] <= obj_rect[:y]
    return false if player_rect[:y] >= obj_rect[:y] + obj_rect[:height]

    true
  end

  def player_in_area?(area)
    @player_x < area[:x] + area[:width] &&
      @player_x + TILE_SIZE > area[:x] &&
      @player_y < area[:y] + area[:height] &&
      @player_y + TILE_SIZE > area[:y]
  end

  def update_camera_position
    # Логика определения позиции камеры
    camera_x = [@player_x - HALF_WINDOW_WIDTH, 0].max
    camera_y = [@player_y - HALF_WINDOW_HEIGHT, 0].max

    map_width_px = @map['width'] * TILE_SIZE
    map_height_px = @map['height'] * TILE_SIZE

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
    if id == Gosu::MS_LEFT

      # Проверяем, находится ли персонаж на целевом тайле

      x = @adjusted_mouse_x
      y = @adjusted_mouse_y

      camera_position_x, camera_position_y = update_camera_position
      target_tile_x = ((x + camera_position_x) / TILE_SIZE).to_i
      target_tile_y = ((y + camera_position_y) / TILE_SIZE).to_i

      start_tile_x = (@player_x / TILE_SIZE).to_i
      start_tile_y = (@player_y / TILE_SIZE).to_i

      path = find_path(start_tile_x, start_tile_y, target_tile_x, target_tile_y)

      if path
        @path = path
        if @moving
          @new_path = true
        else
          start_path
        end
      end

      # pointer_click_animations
      target_x = ((x + camera_position_x) / TILE_SIZE).to_i * TILE_SIZE
      target_y = ((y + camera_position_y) / TILE_SIZE).to_i * TILE_SIZE
      3.times do |i|
        @pointer_click_animations << {
          x: target_x + (i * 2 + 6),
          y: target_y + (i * 2 + 6),
          size: TILE_SIZE - (i * 2 + 6) * 2,
          color: Gosu::Color::WHITE
        }
      end

      if @player_x < target_x
        @direction = :right
      elsif @player_x > target_x
        @direction = :left
      end

    elsif id == Gosu::KB_Q
      @player_spelling = true

      x = @adjusted_mouse_x
      y = @adjusted_mouse_y

      if @projectiles_target
        target_tile_x, target_tile_y = @projectiles_target
      else
        camera_position_x, camera_position_y = update_camera_position
        target_tile_x = ((x + camera_position_x) / TILE_SIZE).to_i
        target_tile_y = ((y + camera_position_y) / TILE_SIZE).to_i
      end

      projectile = Projectile.new(@player_x + HALF_TILE_SIZE,
      @player_y + HALF_TILE_SIZE,
      target_tile_x * TILE_SIZE + HALF_TILE_SIZE,
      target_tile_y * TILE_SIZE + HALF_TILE_SIZE,
      3)
      @projectiles << projectile

    elsif id == Gosu::MS_RIGHT
      x = @adjusted_mouse_x
      y = @adjusted_mouse_y

      camera_position_x, camera_position_y = update_camera_position
      target_tile_x = ((x + camera_position_x) / TILE_SIZE).to_i
      target_tile_y = ((y + camera_position_y) / TILE_SIZE).to_i

      @projectiles_target = [target_tile_x, target_tile_y]

    elsif id == Gosu::KB_ESCAPE
      @projectiles_target = nil
    end
  end

  def start_path
    @path.shift # remove start tile
    return if @path.empty?
    next_tile = @path.shift
    @target_x = next_tile[0] * TILE_SIZE
    @target_y = next_tile[1] * TILE_SIZE
    @moving = true
    @new_path = false
  end

  def find_path(start_x, start_y, goal_x, goal_y)
    open_set = Set.new([[start_x, start_y]])
    came_from = {}
    g_score = Hash.new(Float::INFINITY)
    g_score[[start_x, start_y]] = 0
    f_score = Hash.new(Float::INFINITY)
    f_score[[start_x, start_y]] = heuristic(start_x, start_y, goal_x, goal_y)

    while !open_set.empty?
      current = open_set.min_by { |node| f_score[node] }

      if current == [goal_x, goal_y]
        return reconstruct_path(came_from, current)
      end

      open_set.delete(current)
      x, y = current

      neighbors(x, y).each do |neighbor|
        tentative_g_score = g_score[current] + 1

        if tentative_g_score < g_score[neighbor]
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g_score
          f_score[neighbor] = g_score[neighbor] + heuristic(neighbor[0], neighbor[1], goal_x, goal_y)
          open_set.add(neighbor) unless open_set.include?(neighbor)
        end
      end
    end

    return nil # Путь не найден
  end

  def heuristic(x1, y1, x2, y2)
    (x1 - x2).abs + (y1 - y2).abs
  end

  def reconstruct_path(came_from, current)
    total_path = [current]
    while came_from.has_key?(current)
      current = came_from[current]
      total_path.prepend(current)
    end
    total_path
  end

  def neighbors(x, y)
    possible_moves = [[1, 0], [0, 1], [-1, 0], [0, -1]]
    result = []

    possible_moves.each do |move|
      nx, ny = x + move[0], y + move[1]
      next if nx < 0 || ny < 0 || nx >= @map['width'] || ny >= @map['height']

      tile_index = nx + ny * @map['width']

      tiles = @tiles_info[tile_index]
      tiles_collides = tiles.map do |tile|
        tile['properties'].filter {|prop| prop['name'] == 'collides'}.map {|prop| prop['value']}
      end
      collides = tiles_collides.flatten.include?(true)

      if collides
        next
      else
        result << [nx, ny]
      end
    end

    result
  end

  def move_to_nearest_tile
    dx = @target_x - @player_x
    dy = @target_y - @player_y
    distance = Math.sqrt(dx**2 + dy**2)

    if distance < @player_speed
      @player_x = @target_x
      @player_y = @target_y
    else
      dx /= distance
      dy /= distance
      @player_x += (dx * @player_speed).to_i
      @player_y += (dy * @player_speed).to_i
    end
  end

  def move_player_with_mouse
    return unless @moving

    if @new_path
      move_to_nearest_tile
      return unless @player_x % TILE_SIZE == 0 && @player_y % TILE_SIZE == 0
      start_path
    else
      if @next_step
        next_tile = @path.shift
        if next_tile
          @target_x = next_tile[0] * TILE_SIZE
          @target_y = next_tile[1] * TILE_SIZE
        end
        @next_step = false
      end
    end

    # Определяем направление к цели
    dx = @target_x - @player_x
    dy = @target_y - @player_y
    distance = Math.sqrt(dx**2 + dy**2)

    # Если цель достигнута
    if distance < @player_speed
      @player_x = @target_x
      @player_y = @target_y

      if @path.empty?
        @moving = false
        @next_step = false
      else
        @next_step = true
      end
    else
      # Двигаем игрока в сторону цели
      dx /= distance
      dy /= distance
      @player_x += (dx * @player_speed).to_i
      @player_y += (dy * @player_speed).to_i
    end

    # Ограничиваем движение игрока рамками карты
    @player_x = [[@player_x, 0].max, @map['width'] * TILE_SIZE - @player_width].min
    @player_y = [[@player_y, 0].max, @map['height'] * TILE_SIZE - @player_height].min
  end

  def update
    @adjusted_mouse_x = mouse_x - HALF_INTERFACE_SIZE_WIDTH
    @adjusted_mouse_y = mouse_y - HALF_INTERFACE_SIZE_HEIGHT

    update_player
    move_player_with_buttons
    move_player_with_mouse
    update_camera_position unless @first_frame

    # Сброс флага после первого кадра
    @first_frame = false if @first_frame

    @transition_areas.each do |area|
      if player_in_area?(area)
        # Пример перехода: просто перемещаем игрока на нижнюю границу карты
        @player_x = area[:x] + area[:width] / 2
        @player_y = WINDOW_HEIGHT - 64
        # Ты можешь также перезагрузить другую карту, используя load_map
        load_map(self.instance_variable_get("@map_#{area[:destination]}"))
        break
      end
    end

    @projectiles.each do |projectile|
      projectile.update
    end

    # Удаляем снаряды, которые достигли цели
    @projectiles.reject! { |projectile| projectile.reached_target? }
  end

  def draw
    camera_x, camera_y = update_camera_position
    Gosu.translate(HALF_INTERFACE_SIZE_WIDTH, HALF_INTERFACE_SIZE_HEIGHT) do
      Gosu.translate(-camera_x, -camera_y) do
        # Отрисовка карты и игрока
        @map['layers'].each do |layer|
          next unless layer['type'] == 'tilelayer'

          layer['data'].each_with_index do |tile_id, index|
            next if tile_id == 0

            x = (index % @map['width']) * TILE_SIZE
            y = (index / @map['width']) * TILE_SIZE
            @tiles[tile_id - 1].draw(x, y, 0)
          end
        end

        # Рисуем игрока
        @player_image.draw(@player_x, @player_y, 1)

        @projectiles.each do |projectile|
          projectile.draw
        end

        draw_grid
        draw_projectiles_target
        draw_pointer_rect
        draw_pointer_click
      end
    end

    # Отрисовка интерфейса (рамки и других элементов интерфейса)
    draw_interface
  end

  def draw_grid
    # Рисуем вертикальные линии
    (0..@map['width']).each do |i|
      x = i * TILE_SIZE
      Gosu.draw_line(x, 0, Gosu::Color::BLACK, x, @map['height'] * TILE_SIZE, Gosu::Color::BLACK)
    end

    # Рисуем горизонтальные линии
    (0..@map['height']).each do |i|
      y = i * TILE_SIZE
      Gosu.draw_line(0, y, Gosu::Color::BLACK, @map['width'] * TILE_SIZE, y, Gosu::Color::BLACK)
    end
  end

  def draw_projectiles_target
    return unless @projectiles_target

    target_tile_x, target_tile_y = @projectiles_target
    target_x = target_tile_x * TILE_SIZE
    target_y = target_tile_y * TILE_SIZE

    p1_x = target_x
    p1_y = target_y

    p2_x = target_x + TILE_SIZE
    p2_y = target_y

    p3_x = target_x + TILE_SIZE
    p3_y = target_y + TILE_SIZE

    p4_x = target_x
    p4_y = target_y + TILE_SIZE

    color = Gosu::Color::RED

    Gosu.draw_line(p1_x, p1_y, color, p2_x, p2_y, color)
    Gosu.draw_line(p2_x, p2_y, color, p3_x, p3_y, color)
    Gosu.draw_line(p3_x, p3_y, color, p4_x, p4_y, color)
    Gosu.draw_line(p4_x, p4_y, color, p1_x, p1_y, color)
  end

  def draw_pointer_rect
    x = @adjusted_mouse_x
    y = @adjusted_mouse_y

    camera_position_x, camera_position_y = update_camera_position
    target_x = ((x + camera_position_x) / TILE_SIZE).to_i * TILE_SIZE + 1
    target_y = ((y + camera_position_y) / TILE_SIZE).to_i * TILE_SIZE + 1

    size = TILE_SIZE - 2

    p1_x = target_x
    p1_y = target_y

    p2_x = target_x + size
    p2_y = target_y

    p3_x = target_x + size
    p3_y = target_y + size

    p4_x = target_x
    p4_y = target_y + size

    color = Gosu::Color::WHITE

    Gosu.draw_line(p1_x, p1_y, color, p2_x, p2_y, color)
    Gosu.draw_line(p2_x, p2_y, color, p3_x, p3_y, color)
    Gosu.draw_line(p3_x, p3_y, color, p4_x, p4_y, color)
    Gosu.draw_line(p4_x, p4_y, color, p1_x, p1_y, color)
  end

  def draw_pointer_click
    if !@pointer_click_animations.empty?
      frame = @pointer_click_animations.shift
      Gosu.draw_rect(frame[:x], frame[:y], frame[:size], frame[:size], frame[:color])
    end
  end

  def update_player
    if @player_spelling

      @player_image = @player_spell
      @spelling_counter += 1
      if @spelling_counter >= @spelling_delay
        @player_spelling = false
        @spelling_counter = 0
      else
        return
      end
    end

    if @direction == :right
      @player_image = @sprites_right[@current_frame]
    else
      @player_image = @sprites_left[@current_frame]
    end

    # Обновление кадра для анимации
    if @moving
      @frame_counter += 1
      if @frame_counter >= @frame_delay
        @current_frame = (@current_frame + 1) % @sprites_right.size
        @frame_counter = 0
      end
    else
      @current_frame = 0 # Вернуться в начальное положение, если персонаж не движется
    end
  end

  def draw_interface
    # Верхняя панель
    Gosu.draw_rect(0, 0, WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, HALF_INTERFACE_SIZE_HEIGHT, INTERFACE_COLOR, 2)

    # Нижняя панель
    Gosu.draw_rect(0, WINDOW_HEIGHT + HALF_INTERFACE_SIZE_HEIGHT, WINDOW_WIDTH + INTERFACE_SIZE_WIDTH, HALF_INTERFACE_SIZE_HEIGHT, INTERFACE_COLOR, 2)

    # Левая панель
    Gosu.draw_rect(0, 0, HALF_INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT, INTERFACE_COLOR, 2)

    # Правая панель
    Gosu.draw_rect(WINDOW_WIDTH + HALF_INTERFACE_SIZE_WIDTH, 0, HALF_INTERFACE_SIZE_WIDTH, WINDOW_HEIGHT + INTERFACE_SIZE_HEIGHT, INTERFACE_COLOR, 2)
  end

end

window = GameWindow.new
window.show
