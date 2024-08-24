require_relative 'projectile'

class Player
  attr_accessor :player_x, :player_y, :player_spelling, :player_target, :all_tiles_info, :map_width, :map_height, :map_loader, :xp, :mp
  def initialize(tile_size: 32, all_tiles_info:, map_width:, map_height:, map_loader:)
    @tile_size = tile_size
    @half_tile_size = tile_size / 2

    @spell_image = Gosu::Image.new('assets/wizard_spell.png')
    @move_right_images = Gosu::Image.load_tiles('assets/wizard_right.png', 32, 32)
    @move_left_images = Gosu::Image.load_tiles('assets/wizard_left.png', 32, 32)

    @player_x = 160
    @player_y = 160
    @player_speed = 2
    @player_width = 32
    @player_height = 32

    @player_image = nil
    @current_frame = 0
    @frame_counter = 0
    @frame_delay = 10

    @direction = :right

    @player_spelling = false
    @spelling_counter = 0
    @spelling_delay = 20

    @projectiles = []
    @player_target = nil

    @path = []
    @target_x = nil
    @target_y = nil
    @moving = false
    @new_path = false
    @next_step = false

    @all_tiles_info = all_tiles_info
    @map_width = map_width
    @map_height = map_height
    @map_loader = map_loader

    @xp = 100
    @mp = 100
  end

  def start_moving(path)
    if path
      @path = path
      if @moving
        @new_path = true
      else
        start_path
      end
    end
  end

  def stop_moving
    @moving = false
  end

  def start_path
    @path.shift # remove start tile
    return if @path.empty?
    next_tile = @path.shift
    @target_x = next_tile[0] * @tile_size
    @target_y = next_tile[1] * @tile_size
    @moving = true
    @new_path = false
  end

  def move_player_with_mouse(map_width, map_height)
    return unless @moving

    if @new_path
      move_to_nearest_tile
      return unless @player_x % @tile_size == 0 && @player_y % @tile_size == 0
      start_path
    else
      if @next_step
        next_tile = @path.shift
        if next_tile
          @target_x = next_tile[0] * @tile_size
          @target_y = next_tile[1] * @tile_size
        end
        @next_step = false
      end
    end

    # Определяем направление к цели
    dx = @target_x - @player_x
    dy = @target_y - @player_y
    distance = Math.sqrt(dx**2 + dy**2)

    # Если цель достигнута
    if distance < @player_speed
      @player_x = @target_x
      @player_y = @target_y

      if @path.empty?
        @moving = false
        @next_step = false
      else
        @next_step = true
      end
    else
      # Двигаем игрока в сторону цели
      dx /= distance
      dy /= distance
      @player_x += (dx * @player_speed).to_i
      @player_y += (dy * @player_speed).to_i
    end

    # Ограничиваем движение игрока рамками карты
    @player_x = [[@player_x, 0].max, map_width * @tile_size - @player_width].min
    @player_y = [[@player_y, 0].max, map_height * @tile_size - @player_height].min
  end

  def move_to_nearest_tile
    dx = @target_x - @player_x
    dy = @target_y - @player_y
    distance = Math.sqrt(dx**2 + dy**2)

    if distance < @player_speed
      @player_x = @target_x
      @player_y = @target_y
    else
      dx /= distance
      dy /= distance
      @player_x += (dx * @player_speed).to_i
      @player_y += (dy * @player_speed).to_i
    end
  end

  def player_in_area?(area)
    @player_x < area[:x] + area[:width] &&
      @player_x + @tile_size > area[:x] &&
      @player_y < area[:y] + area[:height] &&
      @player_y + @tile_size > area[:y]
  end

  def set_sprite_direction(target_x, target_y)
    if @player_x < target_x
      @direction = :right
    elsif @player_x > target_x
      @direction = :left
    end
  end

  def update_player_image
    if @player_spelling

      @player_image = @spell_image
      @spelling_counter += 1
      if @spelling_counter >= @spelling_delay
        @player_spelling = false
        @spelling_counter = 0
      else
        return
      end
    end

    if @direction == :right
      @player_image = @move_right_images[@current_frame]
    else
      @player_image = @move_left_images[@current_frame]
    end

    # Обновление кадра для анимации
    if @moving
      @frame_counter += 1
      if @frame_counter >= @frame_delay
        @current_frame = (@current_frame + 1) % @move_right_images.size
        @frame_counter = 0
      end
    else
      @current_frame = 0 # Вернуться в начальное положение, если персонаж не движется
    end
  end

  def create_projectile(pointer_x, pointer_y, camera_position_x, camera_position_y)
    if @player_target
      if @player_target.is_a? Array
        target_tile_x, target_tile_y = @player_target
        target_x = target_tile_x * @tile_size + @half_tile_size
        target_y = target_tile_y * @tile_size + @half_tile_size
      else
        target_tile_x = (@player_target.monster_x / @tile_size).to_i
        target_tile_y = (@player_target.monster_y / @tile_size).to_i

        target_x = @player_target.monster_x + @half_tile_size
        target_y = @player_target.monster_y + @half_tile_size
      end
    else
      target_tile_x = ((pointer_x + camera_position_x) / @tile_size).to_i
      target_tile_y = ((pointer_y + camera_position_y) / @tile_size).to_i
      target_x = target_tile_x * @tile_size + @half_tile_size
      target_y = target_tile_y * @tile_size + @half_tile_size
    end

    return if (@player_x == target_tile_x * @tile_size) && (@player_y == target_tile_y * @tile_size)

    projectile = Projectile.new(
      start_x: @player_x + @half_tile_size,
      start_y: @player_y + @half_tile_size,
      target_x: target_x,
      target_y: target_y,
      speed: 5
    )
    @projectiles << projectile
  end

  def draw_player_target
    return unless @player_target

    if @player_target.is_a? Array
      target_tile_x, target_tile_y = @player_target
      target_x = target_tile_x * @tile_size
      target_y = target_tile_y * @tile_size
    else
      target_x = @player_target.monster_x
      target_y = @player_target.monster_y
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
    return unless @player_target
    return unless !@player_target.is_a? Array

    Gosu.draw_rect(200, 20, @player_target.xp, 10, Gosu::Color::RED, 3)
  end

  def draw_xp_mp_bars
    Gosu.draw_rect(30, 60, 20, @xp * 2, Gosu::Color::RED, 3)
    Gosu.draw_rect(60, 60, 20, @xp * 2, Gosu::Color.new(255, 19, 103, 138), 3)
  end

  def update_projectiles
    @projectiles.each do |projectile|
      projectile.update

      # colliding with map
      current_tile_x = (projectile.x / @tile_size).to_i
      current_tile_y = (projectile.y / @tile_size).to_i

      tile_index = current_tile_x + current_tile_y * @map_width

      tiles = @all_tiles_info[tile_index]
      tiles_collides = tiles.map do |tile|
        tile['properties'].filter {|prop| prop['name'] == 'collides'}.map {|prop| prop['value']}
      end
      collides = tiles_collides.flatten.include?(true)

      if collides
        @projectiles.delete(projectile)
        next
      end

      # colliding with monsters
      monster = @map_loader.monsters.find do |monster|
        ((monster.monster_x / @tile_size).to_i == current_tile_x) && ((monster.monster_y / @tile_size).to_i == current_tile_y)
      end

      if monster
        monster.xp -= 10
        @projectiles.delete(projectile)
        if monster.xp <= 0
          @map_loader.monsters.delete(monster)
        end
        next
      end
    end

    @projectiles.reject! { |projectile| projectile.reached_target? }
  end

  def draw_projectiles
    !@projectiles.empty? && @projectiles.each do |projectile|
      projectile.draw
    end
  end

  def update
    update_player_image
    update_projectiles
  end

  def draw
    @player_image.draw(@player_x, @player_y, 1)
    draw_player_target
    draw_projectiles
  end

end
