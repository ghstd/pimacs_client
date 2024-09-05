module IndividualAbilities
  class DetectInRadius
    def initialize(owner:, radius: 1)
      @world = World.instance
      @owner = owner
      @radius = radius

      @timeout = TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :characters_in_radius,
        delay: 150
      )
    end

    def characters_in_radius
      (-@radius..@radius).each do |dx|
        (-@radius..@radius).each do |dy|

          current_x, current_y = PixelsConverter.pixels_to_tile_coord(@owner.x, @owner.y)
          check_x = current_x + dx
          check_y = current_y + dy
          next unless check_x.between?(0, @world.current_map.width - 1) && check_y.between?(0, @world.current_map.height - 1)

          character = @world.current_map.players.find do |player|
            x, y = PixelsConverter.tile_coord_to_pixels(check_x, check_y)
            (player.x == x) && (player.y == y)
          end

          if character
            @owner.target = character
            return
          end
        end
      end
      @owner.target = nil
    end

    def delete_timeout
      @timeout.delete
    end
  end
end
