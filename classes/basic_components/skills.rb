module BasicComponents
  class Skills
    attr_accessor
    def initialize
      @components = {}
    end

    def add_skill(component)
      @components[component.class] = component
    end

    def get_skill(component_class)
      @components[component_class]
    end
  end
end
