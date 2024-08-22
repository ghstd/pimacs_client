class Player
  def initialize
    @sprites_right = Gosu::Image.load_tiles("path_to_sprite_right.png", 32, 32)
    @sprites_left = Gosu::Image.load_tiles("path_to_sprite_left.png", 32, 32)
    @current_frame = 0
    @direction = :right
    @player_x, @player_y = 100, 100  # стартовая позиция персонажа
  end

  def update
    # Обновление кадра для анимации
    @current_frame += 1
    @current_frame %= @sprites_right.size

    # Логика движения
    if @direction == :right
      @player_x += 1
    elsif @direction == :left
      @player_x -= 1
    end
  end

  def draw
    if @direction == :right
      @sprites_right[@current_frame].draw(@player_x, @player_y, 1)
    else
      @sprites_left[@current_frame].draw(@player_x, @player_y, 1)
    end
  end

  def moving_right?
    # Логика определения движения вправо
  end

  def moving_left?
    # Логика определения движения влево
  end
end
