module Monsters
  class BasicClass
    attr_accessor :x, :y, :width, :height, :speed, :current_image,
      :move_component, :animations_component,
      :target, :respawn_start, :respawn_finish, :xp
    def initialize(x:, y:, speed: 1, respawn_start: nil, respawn_finish: nil)
      @tile_size = $TILE_SIZE
      @half_tile_size = @tile_size / 2

      @world = World.instance
      @x = x
      @y = y
      @width = 32
      @height = 32
      @speed = speed

      @target = nil

      @current_image = nil

      @respawn_start = respawn_start || [0, 0]
      @respawn_finish = respawn_finish || PixelsConverter.pixels_to_tile_coord(@world.current_map.width - @tile_size, @world.current_map.height - @tile_size)

      @xp = 100
    end

    def get_hit(projectile)
      p "#{self.class} hit"
    end

    def update
    end

    def draw
    end
  end

end
