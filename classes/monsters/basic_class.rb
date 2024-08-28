module Monsters
  class BasicClass
    attr_accessor :x, :y, :width, :height, :current_image,
      :move_component, :animations_component, :skills_component,
      :target, :xp, :mp
    def initialize(x, y)
      @tile_size = $TILE_SIZE
      @half_tile_size = @tile_size / 2

      @world = World.instance
      @x = x
      @y = y
      @width = 32
      @height = 32

      @target = nil

      @current_image = nil

      @xp = 100

      @move_component = BasicComponents::Move.new(self)
      @animations_component = BasicComponents::Animations.new(self)

      @animations_component.add_animation(Animations::Walking.new(
        'assets/monster_right.png',
        'assets/monster_left.png',
        32,
        self
      ))

    end

    def get_hit(projectile)
      p "#{self.class} hit"
    end

    def update
      @move_component.update
      @animations_component.update
    end

    def draw
      @animations_component.draw
      draw_player_target
    end
  end

end
