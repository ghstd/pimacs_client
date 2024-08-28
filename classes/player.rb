class Player
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
    @mp = 100

    @move_component = BasicComponents::Move.new(self)
    @animations_component = BasicComponents::Animations.new(self)
    @skills_component = BasicComponents::Skills.new()

    @animations_component.add_animation(Animations::Walking.new(
      'assets/wizard_right.png',
      'assets/wizard_left.png',
      32,
      self
    ))

    @animations_component.add_animation(Animations::Spelling.new(
      'assets/wizard_spell.png',
      self
    ))

    @skills_component.add_skill(SkillsBase::RedBall.new(self))
  end

  def get_hit(projectile)
    p "#{self.class} hit"
  end

  def player_in_area?(area)
    @x < area[:x] + area[:width] &&
      @x + @tile_size > area[:x] &&
      @y < area[:y] + area[:height] &&
      @y + @tile_size > area[:y]
  end

  def draw_player_target
    return unless @target

    if @target.is_a? Array
      target_tile_x, target_tile_y = @target
      target_x = target_tile_x * @tile_size
      target_y = target_tile_y * @tile_size
    else
      target_x = @target.x
      target_y = @target.y
    end

    p1_x = target_x
    p1_y = target_y

    p2_x = target_x + @tile_size
    p2_y = target_y

    p3_x = target_x + @tile_size
    p3_y = target_y + @tile_size

    p4_x = target_x
    p4_y = target_y + @tile_size

    color = Gosu::Color::RED

    Gosu.draw_line(p1_x, p1_y, color, p2_x, p2_y, color)
    Gosu.draw_line(p2_x, p2_y, color, p3_x, p3_y, color)
    Gosu.draw_line(p3_x, p3_y, color, p4_x, p4_y, color)
    Gosu.draw_line(p4_x, p4_y, color, p1_x, p1_y, color)
  end

  def draw_target_xp_bar
    return unless @target
    return unless !@target.is_a? Array

    Gosu.draw_rect(200, 20, @target.xp, 10, Gosu::Color::RED, 3)
  end

  def draw_xp_mp_bars
    Gosu.draw_rect(30, 60, 20, @xp * 2, Gosu::Color::RED, 3)
    Gosu.draw_rect(60, 60, 20, @xp * 2, Gosu::Color.new(255, 19, 103, 138), 3)
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
