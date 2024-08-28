module BasicComponents
  class Animations
    attr_accessor :owner, :current_image
    def initialize(owner = nil)
      @owner = owner

      @components = {}
    end

    def add_animation(component)
      @components[component.class] = component
    end

    def get_animation(component_class)
      @components[component_class]
    end

    def delete_timeouts
      @components.each do |component_class, component|
        component.delete_timeout if component.respond_to?(:delete_timeout)
      end
    end

    def update
      @components.each do |component_class, component|
        component.update if component.respond_to?(:update)
      end
    end

    def draw
      @owner && @owner.current_image.draw(@owner.x, @owner.y, 1) if @owner.instance_variable_defined?(:@current_image)
      @components.each do |component_class, component|
        component.draw if component.respond_to?(:draw)
      end
    end
  end
end
