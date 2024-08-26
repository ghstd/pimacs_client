class Pointer
  def initialize(correction_x: 0, correction_y: 0, window:)
    @tile_size = $TILE_SIZE

    @correction_x = correction_x
    @correction_y = correction_y
    @window = window

    @pointer_click_animations = []
  end

  def current_position
    return @window.mouse_x - @correction_x, @window.mouse_y - @correction_y
  end

  def real_position
    return @window.mouse_x, @window.mouse_y
  end

  def draw_pointer_rect(camera_position_x, camera_position_y)
    x, y = current_position

    target_x = ((x + camera_position_x) / @tile_size).to_i * @tile_size + 1
    target_y = ((y + camera_position_y) / @tile_size).to_i * @tile_size + 1

    size = @tile_size - 2

    p1_x = target_x
    p1_y = target_y

    p2_x = target_x + size
    p2_y = target_y

    p3_x = target_x + size
    p3_y = target_y + size

    p4_x = target_x
    p4_y = target_y + size

    color = Gosu::Color::WHITE

    Gosu.draw_line(p1_x, p1_y, color, p2_x, p2_y, color)
    Gosu.draw_line(p2_x, p2_y, color, p3_x, p3_y, color)
    Gosu.draw_line(p3_x, p3_y, color, p4_x, p4_y, color)
    Gosu.draw_line(p4_x, p4_y, color, p1_x, p1_y, color)
  end

  def init_click_animation(target_x, target_y)
    3.times do |i|
      @pointer_click_animations << {
        x: target_x + (i * 2 + 6),
        y: target_y + (i * 2 + 6),
        size: @tile_size - (i * 2 + 6) * 2,
        color: Gosu::Color::WHITE
      }
    end
  end

  def draw_pointer_click
    if !@pointer_click_animations.empty?
      frame = @pointer_click_animations.shift
      x, y, size,color = frame.values_at(:x, :y, :size, :color)
      Gosu.draw_rect(x, y, size, size, color)
    end
  end
end
