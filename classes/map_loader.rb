class MapLoader
  attr_reader :map, :maps, :map_width, :map_height, :all_tiles_info, :transition_areas, :players, :monsters
  def initialize(maps_pathes: [])
    @map = nil
    @map_width = 0
    @map_height = 0
    @maps = {}
    @all_tiles_info = []
    @transition_areas = []

    # init @maps
    maps_pathes.each do |path|
      name = File.basename(path, File.extname(path))
      data = JSON.parse(File.read(path))
      @maps[name] = data
    end

    @players = Set.new
    @monsters = Set.new
  end

  def load_map(map_name)
    @map = @maps[map_name]
    @map_width = @map['width']
    @map_height = @map['height']

    @all_tiles_info = []
    @transition_areas = []

    # Набор тайлов всех слоев карты
    @map['layers'].each do |layer|
      next if layer['type'] != 'tilelayer'
      layer['data'].each_with_index do |tile_id, index|
        @map['tilesets'].each do |tileset|
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

    # Объекты перемещений
    @map['layers'].each do |layer|
      if layer['type'] == 'objectgroup' && layer['name'] == 'Transition'
        # object = layer['objects'].find {|object| object['name'] == 'transition'}
        object = layer['objects'].each do |object|
          if object['name'] == 'transition'
            string = object['properties'].find { |prop| prop['name'] == 'destination' }['value']
            destination_data = {}
            string.split(',').each do |pair|
              key, value = pair.split(':')
              destination_data[key.to_sym] = value.to_i
            end

            @transition_areas << {
              x: object['x'],
              y: object['y'],
              width: object['width'],
              height: object['height'],
              destination: object['properties'].find { |prop| prop['name'] == 'to' }['value'],
              destination_data: destination_data
            }
          end
        end
      end
    end
  end

end
