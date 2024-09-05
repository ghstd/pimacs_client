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

    def update
      super
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
