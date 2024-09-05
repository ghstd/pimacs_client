module CreatureAnimations
  class SimpleSpell
    attr_accessor :spelling
    def initialize(owner:, image:, spelling_delay: 20)
      @owner = owner
      @spell_image = Gosu::Image.new(image)
      @spelling_delay = spelling_delay
      @timeout = nil
    end

    def animation_start
      @timeout.delete if @timeout

      @timeout = TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :animation_end,
        delay: @spelling_delay,
        type: :once
      )

      @owner.spelling = true
      @owner.current_image = @spell_image
    end

    def animation_end
      @owner.spelling = false
    end
  end
end
