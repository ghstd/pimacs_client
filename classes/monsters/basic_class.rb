module Monsters
  class BasicClass
    attr_accessor :x, :y, :width, :height, :speed, :current_image,
      :target, :respawn_start, :respawn_finish, :xp, :spelling, :skills
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

      @spelling = false

      @respawn_start = respawn_start || [0, 0]
      @respawn_finish = respawn_finish || PixelsConverter.pixels_to_tile_coord(@world.current_map.width - @tile_size, @world.current_map.height - @tile_size)

      @xp = 100

      @animations = []
      @skills = {}
    end

    def add_skill(skill)
      @skills[skill.class] = skill
    end

    def add_animation(animation)
      @animations << animation
    end

    def get_hit(projectile)
      p "#{self.class} hit"
    end

    def update
      @animations.each do |animation|
        animation.update if animation.respond_to?(:update)
      end
    end

    def draw
      @current_image.draw(@x, @y, 1)
    end
  end

end
