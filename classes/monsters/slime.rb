module Monsters
  class Slime < Monsters::BasicClass

    include IndividualAbilities::Move

    def initialize(x:, y:, speed: 1, respawn_start: nil, respawn_finish: nil)
      super(
        x: x,
        y: y,
        speed: speed,
        respawn_start: respawn_start,
        respawn_finish: respawn_finish
      )

      init_move_module

      @threshold = 5
      @server_x = nil
      @server_y = nil
      @normal_speed = @speed
      @slow_coefficient = 0.2

      add_animation(IndividualAbilities::Animations::Walking.new(
        owner: self,
        move_right: 'assets/slime_right.png',
        move_left: 'assets/slime_left.png'
      ))

      add_skill(Skills::SlimeMud.new(owner: self))

      @in_action = false

      @move_random = IndividualAbilities::MoveRandom.new(owner: self)
      @detect_in_radius = IndividualAbilities::DetectInRadius.new(
        owner: self,
        radius: 3
      )
    end

    def action_start
      @in_action = true
      stop_on_nearest_tile
      @move_random.timeout.stop
      @skills[Skills::SlimeMud].use_skill
      TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :action_done,
        delay: 80,
        type: :once
      )
    end

    def action_done
      @in_action = false
      @move_random.timeout.run unless @target
    end

    def adjust_client_speed(client, server, speed, direction)
      difference = client - server

      if difference.abs > @threshold
        if direction == :right
          if difference > 0
            return [speed - @slow_coefficient, 1].max
          else
            return [speed + @slow_coefficient, @normal_speed].min
          end
        end

        if direction == :left
          if difference > 0
            return [speed + @slow_coefficient, @normal_speed].min
          else
            return [speed - @slow_coefficient, 1].max
          end
        end

        if direction == :down
          if difference > 0
            return [speed - @slow_coefficient, 1].max
          else
            return [speed + @slow_coefficient, @normal_speed].min
          end
        end

        if direction == :top
          if difference > 0
            return [speed + @slow_coefficient, @normal_speed].min
          else
            return [speed - @slow_coefficient, 1].max
          end
        end

        return @normal_speed
      else
        return @normal_speed
      end
    end

    def get_direction(client_x, client_y, target_x, target_y)
      if (client_x - target_x).abs > (client_y - target_y).abs
        return :x
      else
        return :y
      end
    end

    def synchronize_speed
      if @server_x && @server_y && @target_of_movement_x && @target_of_movement_y
        direction = get_direction(@x, @y, @target_of_movement_x, @target_of_movement_y)
        if direction == :x
          direction_x = get_direction_x
          speed = adjust_client_speed(@x, @server_x, @speed, direction_x)
          @speed = speed
        end
        if direction == :y
          direction_y = get_direction_y
          speed = adjust_client_speed(@y, @server_y, @speed, direction_y)
          @speed = speed
        end
      end
    end

    def update
      super
      synchronize_speed
      move

      if @target && !@in_action
        action_start
      end
    end

    def draw
      super
    end
  end
end
