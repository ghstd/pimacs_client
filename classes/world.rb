class World
  include Singleton
  attr_accessor :current_map, :tiles, :maps

  def initialize
    @world = JSON.parse(File.read('maps/game.world'))

    @maps = {}
    @world['maps'].each do |map|
      map_name = File.basename(map['fileName'], File.extname(map['fileName']))
      map_data = JSON.parse(File.read("maps/#{map_name}.json"))
      @maps[map_name] = Map.new(map_data)
    end

    @current_map = @maps['4']

    tileset_image_base = Gosu::Image.new('assets/base.png')
    tileset_image_water = Gosu::Image.new('assets/water.png')
    tiles_base = Gosu::Image.load_tiles(tileset_image_base, $TILE_SIZE, $TILE_SIZE)
    tiles_water = Gosu::Image.load_tiles(tileset_image_water, $TILE_SIZE, $TILE_SIZE)
    @tiles = tiles_base + tiles_water
  end

  def change_map(map_name)
    @current_map = @maps[map_name]
  end

  def current_map_name
    result = @maps.find { |map_name, map| map == @current_map }
    map_name = result.first
    return map_name
  end

  def find_creature_by_id(creature_id)
    creature = nil
    @maps.each do |map_name, map|
      creature = map.players.find { |player| player.id == creature_id }
      break if creature
      creature = map.monsters.find { |monster| monster.id == creature_id }
      break if creature
    end
    return creature
  end
end
