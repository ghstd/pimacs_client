module Animations
  class Spelling
    attr_accessor :spelling
    def initialize(spell_image_path, aggregator)
      @spell_image = Gosu::Image.new(spell_image_path)
      @aggregator = aggregator

      @spelling = false
      @spelling_counter = 0
      @spelling_delay = 20
    end

    def update_current_image_when_spelling
      if @spelling

        @aggregator.current_image = @spell_image
        @spelling_counter += 1
        if @spelling_counter >= @spelling_delay
          @spelling = false
          @spelling_counter = 0
        end
      end
    end

    def update
      update_current_image_when_spelling
    end
  end
end
