module SkillsBase
  class Spelling
    def initialize(owner)
      @world = World.instance
      @owner = owner
    end

    def use
      return unless @owner.target

      @owner.animating_component.get_component(Animations::Spelling).spelling = true

      if @owner.target.is_a? Array
        tile_x, tile_y = @owner.target
        x, y = PixelsConverter.tile_coord_to_pixels(tile_x, tile_y)
      else
        x = @owner.target.x
        y = @owner.target.y
      end

      return if @owner.x == x && @owner.y == y

      projectile = Projectile.new(
        start_x: @owner.x + 16,
        start_y: @owner.y + 16,
        target_x: x + 16,
        target_y: y + 16,
        speed: 5
      )
      @world.current_map.projectiles << projectile
    end
  end
end
