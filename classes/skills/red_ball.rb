module Skills
  class RedBall
    def initialize(owner:)
      @owner = owner
      @tile_size = $TILE_SIZE
      @half_tile_size = @tile_size / 2
      @world = World.instance

      @creature_animation = CreatureAnimations::SimpleSpell.new(
        owner: @owner,
        image: 'assets/wizard_spell.png',
        spelling_delay: 20
      )
    end

    def use_skill
      return unless @owner.target

      @creature_animation.animation_start

      if @owner.target.is_a? Array
        tile_x, tile_y = @owner.target
        x, y = PixelsConverter.tile_coord_to_pixels(tile_x, tile_y)
      else
        x = @owner.target.x
        y = @owner.target.y
      end

      return if @owner.x == x && @owner.y == y

      id = IdGenerator.create_id

      WebSocketClient.instance.create_projectile(
        owner_id: @owner.id,
        target_id: (@owner.target.is_a? Array) ? nil : @owner.target.id,
        start_x: @owner.x + @half_tile_size,
        start_y: @owner.y + @half_tile_size,
        target_x: x + @half_tile_size,
        target_y: y + @half_tile_size,
        speed: 5,
        size: 8,
        id: id,
        map_name: @world.current_map_name
      )

      projectile = Projectiles::RedBall.new(
        owner: @owner,
        target: (@owner.target.is_a? Array) ? nil : @owner.target,
        start_x: @owner.x + @half_tile_size,
        start_y: @owner.y + @half_tile_size,
        target_x: x + @half_tile_size,
        target_y: y + @half_tile_size,
        speed: 5,
        size: 8,
        id: id,
        projectile_animation: ProjectileAnimations::RedBall,
        on_target_animation: OnTargetAnimations::RedBall
      )
      @world.current_map.projectiles << projectile
    end
  end
end
