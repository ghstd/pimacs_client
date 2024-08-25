class LiveCreature
  def initialize
    @tile_size = 32
    @half_tile_size = @tile_size / 2

    @x = 160
    @y = 160
    @speed = 2
    @width = 32
    @height = 32

    @path = []
    @target_of_movement_x = nil
    @target_of_movement_y = nil
    @moving = false
    @new_path = false
    @next_step = false
  end

  def get_path(x, y, map_width, map_height)
    start_tile_x, start_tile_y = PixelsConverter.pixels_to_tile_coord(@x, @y)

    path = Pathfinder.find_path(
      start_x: start_tile_x,
      start_y: start_tile_y,
      goal_x: x,
      goal_y: y,
      map_width: map_width,
      map_height: map_height,
      all_tiles_info: @map_loader.all_tiles_info
    )
  end

  def start_moving(x, y, map_width, map_height)
    path = get_path(x, y, map_width, map_height)

    if path
      @path = path
      if @moving
        @new_path = true
      else
        next_step
      end
    end
  end

  def stop_moving
    @moving = false
  end

  def next_step
    @path.shift # remove start tile
    return if @path.empty?
    next_tile = @path.shift
    @target_of_movement_x = next_tile[0] * @tile_size
    @target_of_movement_y = next_tile[1] * @tile_size
    @moving = true
    @new_path = false
  end

  def move(map_width, map_height)
    return unless @moving

    if @new_path
      move_to_nearest_tile
      return unless @x % @tile_size == 0 && @y % @tile_size == 0
      next_step
    else
      if @next_step
        next_tile = @path.shift
        if next_tile
          @target_of_movement_x = next_tile[0] * @tile_size
          @target_of_movement_y = next_tile[1] * @tile_size
        end
        @next_step = false
      end
    end

    # Определяем направление к цели
    dx = @target_of_movement_x - @x
    dy = @target_of_movement_y - @y
    distance = Math.sqrt(dx**2 + dy**2)

    # Если цель достигнута
    if distance < @speed
      @x = @target_of_movement_x
      @y = @target_of_movement_y

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
      @x += (dx * @speed).to_i
      @y += (dy * @speed).to_i
    end

    # Ограничиваем движение игрока рамками карты
    @x = [[@x, 0].max, map_width * @tile_size - @width].min
    @y = [[@y, 0].max, map_height * @tile_size - @height].min
  end

  def move_to_nearest_tile
    dx = @target_of_movement_x - @x
    dy = @target_of_movement_y - @y
    distance = Math.sqrt(dx**2 + dy**2)

    if distance < @speed
      @x = @target_of_movement_x
      @y = @target_of_movement_y
    else
      dx /= distance
      dy /= distance
      @x += (dx * @speed).to_i
      @y += (dy * @speed).to_i
    end
  end

  def update(map_width, map_height)
    move(map_width, map_height)
  end

  def draw

  end
end
