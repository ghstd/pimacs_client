module IndividualAbilities
  class MoveRandom
    attr_accessor :timeout
    def initialize(owner:)
      @owner = owner

      @timeout = TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :change_direction_and_move,
        delay: 360
      )

      change_direction_and_move
    end

    def random_direction
      x1, y1 = @owner.respawn_start
      x2, y2 = @owner.respawn_finish
      return rand(x1..x2), rand(y1..y2)
    end

    def change_direction_and_move
      x, y = random_direction
      @owner.start_moving(x, y)
    end

    def delete_timeout
      @timeout.delete
    end
  end
end
