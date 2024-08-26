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
  end

  def reached_target?
    ( (@x - @target_x).abs < @speed ) && ( (@y - @target_y).abs < @speed )
  end
end
