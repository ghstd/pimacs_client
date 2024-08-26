class Player
  attr_accessor :moving_component, :animating_component, :player_target, :xp, :mp
  def initialize(x, y)
    @tile_size = $TILE_SIZE
    @half_tile_size = @tile_size / 2

    @world = World.instance
    @moving_component = BasicAbilities::Moving.new(x, y)
    @animating_component = BasicAbilities::Animating.new(self)

    @projectiles = []
    @player_target = nil

    @xp = 100
    @mp = 100
  end

  def player_in_area?(area)
    @moving_component.x < area[:x] + area[:width] &&
      @moving_component.x + @tile_size > area[:x] &&
      @moving_component.y < area[:y] + area[:height] &&
      @moving_component.y + @tile_size > area[:y]
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

    return if (@moving_component.x == target_tile_x * @tile_size) && (@moving_component.y == target_tile_y * @tile_size)

    projectile = Projectile.new(
      start_x: @moving_component.x + @half_tile_size,
      start_y: @moving_component.y + @half_tile_size,
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

      tile_index = current_tile_x + current_tile_y * @world.current_map.width

      tiles = @world.current_map.all_tiles_info[tile_index]
      tiles_collides = tiles.map do |tile|
        tile['properties'].filter {|prop| prop['name'] == 'collides'}.map {|prop| prop['value']}
      end
      collides = tiles_collides.flatten.include?(true)

      if collides
        @projectiles.delete(projectile)
        next
      end

      # colliding with monsters
      monster = @world.current_map.monsters.find do |monster|
        ((monster.monster_x / @tile_size).to_i == current_tile_x) && ((monster.monster_y / @tile_size).to_i == current_tile_y)
      end

      if monster
        monster.xp -= 10
        @projectiles.delete(projectile)
        if monster.xp <= 0
          @world.current_map.monsters.delete(monster)
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

  def is_moving?
    @moving_component.moving
  end

  def get_position
    [@moving_component.x, @moving_component.y]
  end

  def update
    @moving_component.update
    @animating_component.update
    update_projectiles
  end

  def draw
    @animating_component.draw
    draw_player_target
    draw_projectiles
  end

end
