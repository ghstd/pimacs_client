module ProjectileAnimations
  class SlimeMud
    def initialize(owner:)
      @owner = owner

      @image = Gosu::Image.new("assets/slime_mud.png")

      @timeout = nil
    end

    def delete_timeout
      @timeout.delete if @timeout
    end

    def draw
      x = @owner.x - @image.width / 2
      y = @owner.y - @image.height / 2
      @image.draw(x, y, 1)
    end
  end
end
