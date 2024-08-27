module BasicAbilities
  class Skillful
    attr_accessor
    def initialize
      @components = {}
    end

    def add_component(component)
      @components[component.class] = component
    end

    def get_component(component_class)
      @components[component_class]
    end
  end
end
