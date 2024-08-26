module BasicAbilities
  class Animating
    attr_accessor :spelling
    def initialize(owner)

      @owner = owner
      @world = World.instance

      @spell_image = Gosu::Image.new('assets/wizard_spell.png')
      @move_right_images = Gosu::Image.load_tiles('assets/wizard_right.png', 32, 32)
      @move_left_images = Gosu::Image.load_tiles('assets/wizard_left.png', 32, 32)

      @direction = :right
      @current_image = nil
      @current_frame = 0
      @frame_counter = 0
      @frame_delay = 10

      @spelling = false
      @spelling_counter = 0
      @spelling_delay = 20
    end

    def set_sprite_direction(target_x)
      x, y = @owner.get_position
      if x < target_x
        @direction = :right
      elsif x > target_x
        @direction = :left
      end
    end

    def update_current_image_when_spelling
      if @spelling

        @current_image = @spell_image
        @spelling_counter += 1
        if @spelling_counter >= @spelling_delay
          @spelling = false
          @spelling_counter = 0
        end
      end
    end

    def update_current_image_when_moving
      return if @spelling

      if @direction == :right
        @current_image = @move_right_images[@current_frame]
      else
        @current_image = @move_left_images[@current_frame]
      end

      # Обновление кадра для анимации
      if @owner.is_moving?
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
      update_current_image_when_spelling
      update_current_image_when_moving
    end

    def draw
      x, y = @owner.get_position
      @current_image.draw(x, y, 1)
    end
  end
end
