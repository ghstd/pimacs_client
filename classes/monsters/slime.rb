module Monsters
  class Slime < Monsters::BasicClass
    def initialize(x:, y:, speed: 1, respawn_start: nil, respawn_finish: nil)
      super(
        x: x,
        y: y,
        speed: speed,
        respawn_start: respawn_start,
        respawn_finish: respawn_finish
      )

      @in_action = false

      @move_component = BasicComponents::Move.new(self)
      @animations_component = BasicComponents::Animations.new(self)
      @skills_component = BasicComponents::Skills.new()
      @move_random_component = SecondaryComponents::MoveRandom.new(self)
      @detect_in_radius_component = SecondaryComponents::DetectInRadius.new(
        owner: self,
        radius: 3
      )

      @animations_component.add_animation(Animations::Walking.new(
        'assets/slime_right.png',
        'assets/slime_left.png',
        32,
        self
      ))

      @animations_component.add_animation(Animations::Spelling.new(
        'assets/slime_spell.png',
        self,
        10
      ))

      @skills_component.add_skill(SkillsBase::SlimeMud.new(self))
    end

    def action_start
      @in_action = true
      @move_component.stop_on_nearest_tile
      @move_random_component.timeout.stop
      @skills_component.get_skill(SkillsBase::SlimeMud).use
      TimeoutsRegistrator.add_timeout(
        observer: self,
        method: :action_done,
        delay: 80,
        type: :once
      )
    end

    def action_done
      @in_action = false
      @move_random_component.timeout.run unless @target
    end

    def update
      @move_component.update
      @animations_component.update

      if @target && !@in_action
        action_start
      end
    end

    def draw
      @animations_component.draw
    end
  end
end
