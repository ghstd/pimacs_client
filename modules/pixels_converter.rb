module PixelsConverter
  TILE_SIZE = $TILE_SIZE

  def self.pixels_to_tile_coord(x, y, tile_size = TILE_SIZE)
    tile_x = (x / tile_size).to_i
    tile_y = (y / tile_size).to_i
    return tile_x, tile_y
  end

  def self.pixels_to_tile_index(x, y, width_in_tiles, tile_size = TILE_SIZE)
    tile_x, tile_y = self.pixels_to_tile_coord(x, y, tile_size)
    index = tile_x + tile_y * width_in_tiles
    return index
  end

  def self.round_off_pixels(x, y, tile_size = TILE_SIZE)
    tile_x, tile_y = self.pixels_to_tile_coord(x, y, tile_size)
    rounded_x = tile_x * tile_size
    rounded_y = tile_y * tile_size
    return rounded_x, rounded_y
  end

  def self.tile_coord_to_pixels(tile_x, tile_y, tile_size = TILE_SIZE)
    x = tile_x * tile_size
    y = tile_y * tile_size
    return x, y
  end

end
