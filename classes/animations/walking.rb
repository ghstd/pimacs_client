module Animations
  class Walking
    def initialize(move_right_images_path, move_left_images_path, tile_size, aggregator)
      @move_right_images = Gosu::Image.load_tiles(move_right_images_path, tile_size, tile_size)
      @move_left_images = Gosu::Image.load_tiles(move_left_images_path, tile_size, tile_size)
      @aggregator = aggregator

      @direction = :right
      @direction_updated = false
      @current_frame = 0
      @frame_counter = 0
      @frame_delay = 10
    end

    def update_sprite_direction
      if @aggregator.owner.moving_component.is_new_path?
        @direction_updated = false
      end

      if @aggregator.owner.moving_component.is_moving?
        return if @direction_updated
        @direction_updated = true
        if direction = @aggregator.owner.moving_component.get_direction
          @direction = direction
        end
      else
        @direction_updated = false
      end
    end

    def update_current_image_when_moving
      return if @spelling

      if @direction == :right
        @aggregator.current_image = @move_right_images[@current_frame]
      else
        @aggregator.current_image = @move_left_images[@current_frame]
      end

      # Обновление кадра для анимации
      if @aggregator.owner.moving_component.is_moving?
        @frame_counter += 1
        if @frame_counter >= @frame_delay
          @current_frame = (@current_frame + 1) % @move_right_images.size
          @frame_counter = 0
        end
      else
        @current_frame = 0 # Вернуться в начальное положение, если персонаж не движется
      end
    end

    def update
      update_sprite_direction
      update_current_image_when_moving
    end
  end
end
