module SkillsBase
  class SlimeMud
    def initialize(owner)
      @tile_size = $TILE_SIZE
      @half_tile_size = @tile_size / 2
      @world = World.instance
      @owner = owner
    end

    def use
      return unless @owner.target

      @owner.animations_component.get_animation(Animations::Spelling)&.spelling = true

      if @owner.target.is_a? Array
        tile_x, tile_y = @owner.target
        x, y = PixelsConverter.tile_coord_to_pixels(tile_x, tile_y)
      else
        x = @owner.target.x
        y = @owner.target.y
      end

      return if @owner.x == x && @owner.y == y

      projectile = Projectiles::SlimeMud.new(
        owner: @owner,
        target: (@owner.target.is_a? Array) ? nil : @owner.target,
        start_x: @owner.x + @half_tile_size,
        start_y: @owner.y + @half_tile_size,
        target_x: x + @half_tile_size,
        target_y: y + @half_tile_size,
        speed: 4,
        size: 10
      )
      @world.current_map.projectiles << projectile
    end
  end
end
