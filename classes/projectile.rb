class Projectile
  attr_reader :x, :y

  def initialize(start_x:, start_y:, target_x:, target_y:, speed:, size: 6)
    @x = start_x
    @y = start_y
    @target_x = target_x
    @target_y = target_y
    @speed = speed
    @size = size

    # Определяем направление движения
    dx = @target_x - @x
    dy = @target_y - @y
    distance = Math.sqrt(dx**2 + dy**2)
    @velocity_x = (dx / distance) * @speed
    @velocity_y = (dy / distance) * @speed
  end

  def update
    @x += @velocity_x
    @y += @velocity_y
  end

  def draw
    # Здесь нужно нарисовать снаряд
    Gosu.draw_rect(@x - @size / 2, @y - @size / 2, @size, @size, Gosu::Color::RED)
    # self.draw_circle(@x, @y, 5, Gosu::Color::RED)
  end

  def reached_target?
    ( (@x - @target_x).abs < @speed ) && ( (@y - @target_y).abs < @speed )
  end

  # def draw_circle(x, y, radius, color, segments = 6)
  #   angle_step = 360.0 / segments

  #   segments.times do |i|
  #     angle1 = Gosu.degrees_to_radians(angle_step * i)
  #     angle2 = Gosu.degrees_to_radians(angle_step * (i + 1))

  #     x1 = x + Gosu.offset_x(angle1, radius)
  #     y1 = y + Gosu.offset_y(angle1, radius)
  #     x2 = x + Gosu.offset_x(angle2, radius)
  #     y2 = y + Gosu.offset_y(angle2, radius)

  #     Gosu.draw_line(x1, y1, color, x2, y2, color)
  #   end
  # end
end
