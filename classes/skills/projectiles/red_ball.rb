module Projectiles
  class RedBall < Projectiles::BasicClass
    def initialize(
      owner:,
      target: nil,
      start_x:,
      start_y:,
      target_x:,
      target_y:,
      speed:,
      size: 8,
      id: nil,
      projectile_animation:,
      on_target_animation:
    )

      super(
        owner: owner,
        target: target,
        start_x: start_x,
        start_y: start_y,
        target_x: target_x,
        target_y: target_y,
        speed: speed,
        size: size,
        id: id
      )

      @projectile_animation = projectile_animation
      @on_target_animation = on_target_animation

      add_animation(projectile_animation.new(owner: self))
    end

    def delete_projectile
      super
      @world.current_map.animations << @on_target_animation.new(owner: self)
    end
  end
end
