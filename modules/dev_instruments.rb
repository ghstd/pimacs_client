module DevInstruments
  def self.draw_grid(width, height, tile_size)
    # Рисуем вертикальные линии
    (0..width).each do |i|
      x = i * tile_size
      Gosu.draw_line(x, 0, Gosu::Color::BLACK, x, height * tile_size, Gosu::Color::BLACK)
    end

    # Рисуем горизонтальные линии
    (0..height).each do |i|
      y = i * tile_size
      Gosu.draw_line(0, y, Gosu::Color::BLACK, width * tile_size, y, Gosu::Color::BLACK)
    end
  end
end
