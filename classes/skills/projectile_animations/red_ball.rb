module ProjectileAnimations
  class RedBall
    def initialize(owner:)
      @owner = owner
      @size = @owner.size
      @timeout = TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :change_size,
        delay: 5
      )
      @switcher = true
    end

    def change_size
      if @switcher
        @size -= 3
        @switcher = false
      else
        @size += 3
        @switcher = true
      end
    end

    def delete_timeout
      @timeout.delete if @timeout
    end

    def draw
      x = @owner.x - @size / 2
      y = @owner.y - @size / 2
      Gosu.draw_rect(x, y, @size, @size, Gosu::Color::RED)
    end
  end
end
