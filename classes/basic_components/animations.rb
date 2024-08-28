module BasicComponents
  class Animations
    attr_accessor :owner, :current_image
    def initialize(owner)
      @owner = owner

      @components = {}
    end

    def add_animation(component)
      @components[component.class] = component
    end

    def get_animation(component_class)
      @components[component_class]
    end

    def update
      @components.each do |component_class, component|
        component.update
      end
    end

    def draw
      @owner.current_image.draw(@owner.x, @owner.y, 1)
    end
  end
end
