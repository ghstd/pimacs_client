module BasicComponents
  class Move
    attr_accessor
    def initialize(owner)
      @tile_size = $TILE_SIZE
      @half_tile_size = @tile_size / 2

      @world = World.instance
      @owner = owner

      @path = []
      @final_goal = []
      @target_of_movement_x = nil
      @target_of_movement_y = nil
      @moving = false
      @new_path = false
      @next_step = false
      @stop_on_nearest_tile = false
    end

    def start_moving(x, y)
      path = get_path(x, y)

      if path
        @final_goal = [x * @tile_size, y * @tile_size]
        @path = path
        if @moving
          @new_path = true
        else
          next_step
        end
      end
    end

    def get_path(x, y)
      start_tile_x, start_tile_y = PixelsConverter.pixels_to_tile_coord(@owner.x, @owner.y)

      path = Pathfinder.find_path(
        start_x: start_tile_x,
        start_y: start_tile_y,
        goal_x: x,
        goal_y: y,
        map_width: @world.current_map.width,
        map_height: @world.current_map.height,
        all_tiles_info: @world.current_map.all_tiles_info
      )
    end

    def stop_moving
      @moving = false
    end

    def stop_on_nearest_tile
      @stop_on_nearest_tile = true
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

    def move
      return unless @moving

      if @new_path
        move_to_nearest_tile
        return unless @owner.x % @tile_size == 0 && @owner.y % @tile_size == 0
        next_step
      elsif @stop_on_nearest_tile
        move_to_nearest_tile
        return
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
      dx = @target_of_movement_x - @owner.x
      dy = @target_of_movement_y - @owner.y
      distance = Math.sqrt(dx**2 + dy**2)

      # Если цель достигнута
      if distance < @owner.speed
        @owner.x = @target_of_movement_x
        @owner.y = @target_of_movement_y

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
        @owner.x += (dx * @owner.speed).to_i
        @owner.y += (dy * @owner.speed).to_i
      end

      # Ограничиваем движение игрока рамками карты
      @owner.x = [[@owner.x, 0].max, @world.current_map.width * @tile_size - @owner.width].min
      @owner.y = [[@owner.y, 0].max, @world.current_map.height * @tile_size - @owner.height].min
    end

    def move_to_nearest_tile
      dx = @target_of_movement_x - @owner.x
      dy = @target_of_movement_y - @owner.y
      distance = Math.sqrt(dx**2 + dy**2)

      if distance < @owner.speed
        @owner.x = @target_of_movement_x
        @owner.y = @target_of_movement_y

        stop_moving if @stop_on_nearest_tile
        @stop_on_nearest_tile = false
      else
        dx /= distance
        dy /= distance
        @owner.x += (dx * @owner.speed).to_i
        @owner.y += (dy * @owner.speed).to_i
      end
    end

    def is_moving?
      @moving
    end

    def is_new_path?
      @new_path
    end

    def get_position
      [@owner.x, @owner.y]
    end

    def get_direction
      target_x, target_y = @final_goal
      x, y = get_position

      if x < target_x
        return :right
      elsif x > target_x
        return :left
      else
        nil
      end
    end

    def update
      move
    end
  end
end
