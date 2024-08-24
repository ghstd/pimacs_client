class Monster
  attr_reader :monster_x, :monster_y
  attr_accessor :xp
  def initialize(tile_size: 32, map_width:, map_height:, all_tiles_info:)
    @tile_size = tile_size
    @half_tile_size = tile_size / 2

    @move_right_images = Gosu::Image.load_tiles('assets/monster_right.png', 32, 32)
    @move_left_images = Gosu::Image.load_tiles('assets/monster_left.png', 32, 32)

    @monster_x = 192
    @monster_y = 128
    @monster_speed = 1
    @monster_width = 32
    @monster_height = 32

    @monster_image = nil
    @current_frame = 0
    @frame_counter = 0
    @frame_delay = 10

    @direction = :right

    @path = []
    @target_x = nil
    @target_y = nil
    @moving = false
    @new_path = false
    @next_step = false

    @map_width = map_width
    @map_height = map_height
    @all_tiles_info = all_tiles_info

    @change_move_direction_counter = 0
    @change_move_direction_delay = 250

    target_tile_x, target_tile_y = random_moving_target
    moving(target_tile_x, target_tile_y)

    @xp = 100
  end

  def start_moving(path)
    if path
      @path = path
      if @moving
        @new_path = true
      else
        start_path
      end
    end
  end

  def stop_moving
    @moving = false
  end

  def start_path
    @path.shift # remove start tile
    return if @path.empty?
    next_tile = @path.shift
    @target_x = next_tile[0] * @tile_size
    @target_y = next_tile[1] * @tile_size
    @moving = true
    @new_path = false
  end

  def move_monster_with_mouse(map_width, map_height)
    return unless @moving

    if @new_path
      move_to_nearest_tile
      return unless @monster_x % @tile_size == 0 && @monster_y % @tile_size == 0
      start_path
    else
      if @next_step
        next_tile = @path.shift
        if next_tile
          @target_x = next_tile[0] * @tile_size
          @target_y = next_tile[1] * @tile_size
        end
        @next_step = false
      end
    end

    # Определяем направление к цели
    dx = @target_x - @monster_x
    dy = @target_y - @monster_y
    distance = Math.sqrt(dx**2 + dy**2)

    # Если цель достигнута
    if distance < @monster_speed
      @monster_x = @target_x
      @monster_y = @target_y

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
      @monster_x += (dx * @monster_speed).to_i
      @monster_y += (dy * @monster_speed).to_i
    end

    # Ограничиваем движение игрока рамками карты
    @monster_x = [[@monster_x, 0].max, map_width * @tile_size - @monster_width].min
    @monster_y = [[@monster_y, 0].max, map_height * @tile_size - @monster_height].min
  end

  def move_to_nearest_tile
    dx = @target_x - @monster_x
    dy = @target_y - @monster_y
    distance = Math.sqrt(dx**2 + dy**2)

    if distance < @monster_speed
      @monster_x = @target_x
      @monster_y = @target_y
    else
      dx /= distance
      dy /= distance
      @monster_x += (dx * @monster_speed).to_i
      @monster_y += (dy * @monster_speed).to_i
    end
  end

  def set_sprite_direction(target_x, target_y)
    if @monster_x < target_x
      @direction = :right
    elsif @monster_x > target_x
      @direction = :left
    end
  end

  def update_monster_image
    # if @monster_spelling

    #   @monster_image = @spell_image
    #   @spelling_counter += 1
    #   if @spelling_counter >= @spelling_delay
    #     @monster_spelling = false
    #     @spelling_counter = 0
    #   else
    #     return
    #   end
    # end

    if @direction == :right
      @monster_image = @move_right_images[@current_frame]
    else
      @monster_image = @move_left_images[@current_frame]
    end

    # Обновление кадра для анимации
    if @moving
      @frame_counter += 1
      if @frame_counter >= @frame_delay
        @current_frame = (@current_frame + 1) % @move_right_images.size
        @frame_counter = 0
      end
    else
      @current_frame = 0 # Вернуться в начальное положение, если персонаж не движется
    end
  end

  def moving(target_tile_x, target_tile_y)
    start_tile_x = (@monster_x / @tile_size).to_i
    start_tile_y = (@monster_y / @tile_size).to_i

    path = Pathfinder.find_path(
      start_x: start_tile_x,
      start_y: start_tile_y,
      goal_x: target_tile_x,
      goal_y: target_tile_y,
      map_width: @map_width,
      map_height: @map_height,
      all_tiles_info: @all_tiles_info
    )

    start_moving(path)
    set_sprite_direction(target_tile_x * @tile_size, target_tile_y * @tile_size)
  end

  def random_moving_target
    return rand(3..11), rand(1..8)
  end

  def change_move_direction
    if @change_move_direction_counter >= @change_move_direction_delay
      target_tile_x, target_tile_y = random_moving_target
      moving(target_tile_x, target_tile_y)
      @change_move_direction_counter = 0
    else
      @change_move_direction_counter += 1
    end
  end

  def update
    update_monster_image
    move_monster_with_mouse(@map_width, @map_height)
    # update_projectiles
    change_move_direction
  end

  def draw
    @monster_image.draw(@monster_x, @monster_y, 1)
    # draw_monster_target
    # draw_projectiles
  end
end
