class Player
  attr_accessor :x, :y, :width, :height, :speed, :current_image,
    :target, :xp, :mp, :spelling, :skills, :id, :timestamp,
    :server_x, :server_y

  include IndividualAbilities::Move

  def initialize(x, y)
    @tile_size = $TILE_SIZE
    @half_tile_size = @tile_size / 2

    @world = World.instance
    @x = x
    @y = y
    @width = 32
    @height = 32
    @speed = 2

    @target = nil

    @current_image = nil

    @spelling = false

    @xp = 100
    @mp = 100

    @id = 1

    @timestamp = Time.now
    @threshold = 5
    @server_x = nil
    @server_y = nil
    @normal_speed = @speed
    @slow_coefficient = 0.2

    init_move_module

    @animations = []

    add_animation(IndividualAbilities::Animations::Walking.new(
      owner: self,
      move_right: 'assets/wizard_right.png',
      move_left: 'assets/wizard_left.png'
    ))

    @skills = {}

    add_skill(Skills::RedBall.new(owner: self))
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

  def adjust_client_speed(client, server, speed, direction)
    difference = client - server

    if difference.abs > @threshold
      if direction == :right
        if difference > 0
          return [speed - @slow_coefficient, 1].max
        else
          return [speed + @slow_coefficient, @normal_speed].min
        end
      end

      if direction == :left
        if difference > 0
          return [speed + @slow_coefficient, @normal_speed].min
        else
          return [speed - @slow_coefficient, 1].max
        end
      end

      if direction == :down
        if difference > 0
          return [speed - @slow_coefficient, 1].max
        else
          return [speed + @slow_coefficient, @normal_speed].min
        end
      end

      if direction == :top
        if difference > 0
          return [speed + @slow_coefficient, @normal_speed].min
        else
          return [speed - @slow_coefficient, 1].max
        end
      end

      return @normal_speed
    else
      return @normal_speed
    end
  end

  def get_direction(client_x, client_y, target_x, target_y)
    if (client_x - target_x).abs > (client_y - target_y).abs
      return :x
    else
      return :y
    end
  end

  def synchronize_speed
    if @server_x && @server_y && @target_of_movement_x && @target_of_movement_y
      direction = get_direction(@x, @y, @target_of_movement_x, @target_of_movement_y)
      if direction == :x
        direction_x = get_direction_x
        speed = adjust_client_speed(@x, @server_x, @speed, direction_x)
        @speed = speed
      end
      if direction == :y
        direction_y = get_direction_y
        speed = adjust_client_speed(@y, @server_y, @speed, direction_y)
        @speed = speed
      end
    end
  end

  def update
    synchronize_speed
    move

    @animations.each do |animation|
      animation.update if animation.respond_to?(:update)
    end
  end

  def draw
    draw_player_target
    @current_image.draw(@x, @y, 1)
  end
end
