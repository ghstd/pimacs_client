class Interface
  def initialize(window_width:, window_height:, interface_width:, interface_height:, color:)
    @window_width = window_width
    @window_height = window_height

    @interface_width = interface_width
    @interface_height = interface_height
    @half_interface_width = interface_width / 2
    @half_interface_height = interface_height / 2

    @color = color
  end

  def draw_interface
    # Верхняя панель
    Gosu.draw_rect(0, 0, @window_width + @interface_width, @half_interface_height, @color, 2)

    # Нижняя панель
    Gosu.draw_rect(0, @window_height + @half_interface_height, @window_width + @interface_width, @half_interface_height, @color, 2)

    # Левая панель
    Gosu.draw_rect(0, 0, @half_interface_width, @window_height + @interface_height, @color, 2)

    # Правая панель
    Gosu.draw_rect(@window_width + @half_interface_width, 0, @half_interface_width, @window_height + @interface_height, @color, 2)
  end
end
