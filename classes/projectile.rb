class Projectile
  attr_reader :x, :y

  def initialize(start_x:, start_y:, target_x:, target_y:, speed:, size: 6)
    @world = World.instance

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

  def reached_target?
    ( (@x - @target_x).abs < @speed ) && ( (@y - @target_y).abs < @speed )
  end

  def update
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
      @world.current_map.projectiles.delete(self)
      return
    end

    # colliding with monsters
    monster = @world.current_map.monsters.find do |monster|
      monster_x, monster_y = PixelsConverter.pixels_to_tile_coord(monster.x, monster.y)
      (monster_x == current_tile_x) && (monster_y == current_tile_y)
    end

    if monster
      monster.get_hit(self)
      @world.current_map.projectiles.delete(self)
      return
    end

    if reached_target?
      @world.current_map.projectiles.delete(self)
    end
  end

  def draw
    Gosu.draw_rect(@x - @size / 2, @y - @size / 2, @size, @size, Gosu::Color::RED)
  end
end
