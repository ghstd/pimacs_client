module Projectiles
  class SlimeMud < BasicClass
    def initialize(owner:, target: nil, start_x:, start_y:, target_x:, target_y:, speed:, size: 8)
      super(
        owner: owner,
        target: target,
        start_x: start_x,
        start_y: start_y,
        target_x: target_x,
        target_y: target_y,
        speed: speed,
        size: size
      )

      @animations_component.add_animation(Animations::Skills::SlimeMud.new(self))
    end

    def delete_projectile
      super
      @world.current_map.animations << Animations::Skills::RedBallSplash.new(@x, @y, 3)
    end
  end
end
