module BasicAbilities
  class Animating
    attr_accessor :owner, :current_image
    def initialize(owner)
      @owner = owner

      @components = {}
      @current_image = nil
    end

    def add_component(component)
      @components[component.class] = component
    end

    def get_component(component_class)
      @components[component_class]
    end

    def update
      @components.each do |component_class, component|
        component.update
      end
    end

    def draw
      @current_image.draw(@owner.x, @owner.y, 1)
    end
  end
end
