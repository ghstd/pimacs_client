module Pathfinder

  def self.find_path(start_x:, start_y:, goal_x:, goal_y:, map_width:, map_height:, all_tiles_info:)
    open_set = Set.new([[start_x, start_y]])
    came_from = {}
    g_score = Hash.new(Float::INFINITY)
    g_score[[start_x, start_y]] = 0
    f_score = Hash.new(Float::INFINITY)
    f_score[[start_x, start_y]] = Pathfinder.heuristic(start_x, start_y, goal_x, goal_y)

    while !open_set.empty?
      current = open_set.min_by { |node| f_score[node] }

      if current == [goal_x, goal_y]
        return Pathfinder.reconstruct_path(came_from, current)
      end

      open_set.delete(current)
      x, y = current

      Pathfinder.neighbors(x, y, map_width, map_height, all_tiles_info).each do |neighbor|
        tentative_g_score = g_score[current] + 1

        if tentative_g_score < g_score[neighbor]
          came_from[neighbor] = current
          g_score[neighbor] = tentative_g_score
          f_score[neighbor] = g_score[neighbor] + heuristic(neighbor[0], neighbor[1], goal_x, goal_y)
          open_set.add(neighbor) unless open_set.include?(neighbor)
        end
      end
    end

    return nil # Путь не найден
  end

  def self.heuristic(x1, y1, x2, y2)
    (x1 - x2).abs + (y1 - y2).abs
  end

  def self.reconstruct_path(came_from, current)
    total_path = [current]
    while came_from.has_key?(current)
      current = came_from[current]
      total_path.prepend(current)
    end
    total_path
  end

  def self.neighbors(x, y, map_width, map_height, all_tiles_info)
    possible_moves = [[1, 0], [0, 1], [-1, 0], [0, -1]]
    result = []

    possible_moves.each do |move|
      nx, ny = x + move[0], y + move[1]
      next if nx < 0 || ny < 0 || nx >= map_width || ny >= map_height

      tile_index = nx + ny * map_width

      tiles = all_tiles_info[tile_index]
      tiles_collides = tiles.map do |tile|
        tile['properties'].filter {|prop| prop['name'] == 'collides'}.map {|prop| prop['value']}
      end
      collides = tiles_collides.flatten.include?(true)

      if collides
        next
      else
        result << [nx, ny]
      end
    end

    result
  end

end
