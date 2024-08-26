class Map
  attr_accessor :width, :height, :tile_layers, :all_tiles_info, :transition_areas, :players, :monsters
  TILE_SIZE = $TILE_SIZE
  def initialize(map_data)
    @map_data = map_data
    @width = @map_data['width']
    @height = @map_data['height']

    @tile_layers = []
    @object_layers = []

    @all_tiles_info = []
    @transition_areas = []

    @players = Set.new
    @monsters = Set.new

    init_layers
    init_tiles_info
    init_transition_areas
    init_monsters
  end

  def init_layers
    @map_data['layers'].each do |layer|
      case layer['type']
        when 'tilelayer'
          @tile_layers << layer
        when 'objectgroup'
          @object_layers << layer
      end
    end
  end

  def init_tiles_info
    @tile_layers.each do |layer|
      layer['data'].each_with_index do |tile_id, index|
        @map_data['tilesets'].each do |tileset|
          next if !(tileset['firstgid']..tileset['tilecount']).cover?(tile_id)
          tile = tileset['tiles'].find { |tile| tile['id'] == (tile_id - 1) }
          next unless tile
          if @all_tiles_info[index].nil?
            @all_tiles_info[index] = [tile]
          else
            @all_tiles_info[index] << tile
          end
        end
      end
    end
  end

  def init_transition_areas
    @object_layers.each do |layer|
      if layer['name'] == 'Transition'
        object = layer['objects'].each do |object|
          if object['name'] == 'transition'
            string = object['properties'].find { |prop| prop['name'] == 'destination' }['value']
            destination = {}
            string.split(',').each do |pair|
              key, value = pair.split(':')
              destination[key.to_sym] = value.to_i
            end

            @transition_areas << {
              x: object['x'],
              y: object['y'],
              width: object['width'],
              height: object['height'],
              to_map: object['properties'].find { |prop| prop['name'] == 'to_map' }['value'],
              destination: destination
            }
          end
        end
      end
    end
  end

  def init_monsters
    @object_layers.each do |layer|
      next unless layer['name'] == 'Monsters'
      layer['objects'].each do |object|
        quantity = object['properties'].find { |prop| prop['name'] == 'quantity' }['value']
        quantity.times do
          x = (rand(object['x']..(object['x'] + object['width'] - TILE_SIZE)) / TILE_SIZE).to_i * TILE_SIZE
          y = (rand(object['y']..(object['y'] + object['height'] - TILE_SIZE)) / TILE_SIZE).to_i * TILE_SIZE
          monster = Object.const_get(object['name'].capitalize).new(
            x: x,
            y: y,
            tile_size: TILE_SIZE,
            map_width: @width,
            map_height: @height,
            all_tiles_info: @all_tiles_info
          )
          @monsters << monster
        end
      end
    end
  end

end
