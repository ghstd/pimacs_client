module OnTargetAnimations
  class RedBall
    def initialize(owner:)
      @x = owner.x
      @y = owner.y
      @size = 3
      @timeout = TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :delete_animation,
        delay: 18,
        type: :once
      )
      @switcher = true
    end

    def delete_animation
      World.instance.current_map.animations.delete(self)
    end

    def delete_timeout
      @timeout.delete
    end

    def draw
      Gosu.draw_rect(rand(@x-2..@x+2), rand(@y-2..@y+2), @size, @size, Gosu::Color::RED)
      Gosu.draw_rect(rand(@x-4..@x+4), rand(@y-4..@y+4), @size, @size, Gosu::Color.new(255, 232, 126, 12))
      Gosu.draw_rect(rand(@x-6..@x+6), rand(@y-6..@y+6), @size, @size, Gosu::Color.new(255, 138, 12, 232))
      Gosu.draw_rect(rand(@x-8..@x+8), rand(@y-8..@y+8), @size, @size, Gosu::Color.new(128, 242, 208, 39))
      Gosu.draw_rect(rand(@x-10..@x+10), rand(@y-10..@y+10), @size, @size, Gosu::Color.new(255, 242, 110, 35))
    end
  end
end
