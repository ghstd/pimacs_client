class Projectile
  attr_reader :x, :y, :size

  def initialize(target: nil, start_x:, start_y:, target_x:, target_y:, speed:, size: 8)
    @world = World.instance

    @target = target
    @x = start_x
    @y = start_y
    @target_x = target_x
    @target_y = target_y
    @speed = speed
    @size = size

    @animations_component = BasicComponents::Animations.new(self)
    @animations_component.add_animation(Animations::Skills::RedBall.new(self))
    set_movement_direction
  end

  def set_movement_direction
    if @target
      @target_x = @target.x + @target.width / 2
      @target_y = @target.y + @target.height / 2
    end
    dx = @target_x - @x
    dy = @target_y - @y
    distance = Math.sqrt(dx**2 + dy**2)
    @velocity_x = (dx / distance) * @speed
    @velocity_y = (dy / distance) * @speed
  end

  def reached_target?
    ( (@x - @target_x).abs < @speed ) && ( (@y - @target_y).abs < @speed )
  end

  def delete_projectile
    @animations_component.delete_timeouts
    @world.current_map.projectiles.delete(self)
    @world.current_map.animations << Animations::Skills::RedBallSplash.new(@x, @y, 3)
  end

  def update
    if @target && (@target.x != @target_x || @target.y != @target_y)
      set_movement_direction
    end

    @x += @velocity_x
    @y += @velocity_y

    # colliding with barriers
    current_tile_x, current_tile_y = PixelsConverter.pixels_to_tile_coord(@x, @y)
    tile_index = current_tile_x + current_tile_y * @world.current_map.width
    tiles = @world.current_map.all_tiles_info[tile_index]

    tiles_collides = tiles.map do |tile|
      tile['properties'].filter {|prop| prop['name'] == 'collides'}.map {|prop| prop['value']}
    end
    collides = tiles_collides.flatten.include?(true)

    if collides
      delete_projectile
      return
    end

    # colliding with monsters
    monster = @world.current_map.monsters.find do |monster|
      monster_x, monster_y = PixelsConverter.pixels_to_tile_coord(monster.x, monster.y)
      (monster_x == current_tile_x) && (monster_y == current_tile_y)
    end

    if monster
      monster.get_hit(self)
      delete_projectile
      return
    end

    if reached_target?
      delete_projectile
    end

    @animations_component.update
  end

  def draw
    @animations_component.draw
  end
end
