module TimeoutsRegistrator
  @timeouts = []

  def self.info
    @timeouts.count
  end

  def self.add_timeout(observer:, method:, delay:, type: :infinity, times: 1)
    timeout = TimeoutsRegistrator::Timeout.new(delay, type, times)
    timeout.add_observer(observer, method)
    @timeouts.push(timeout)
    return timeout
  end

  def self.remove_timeout(timeout)
    @timeouts.delete(timeout)
  end

  def self.update
    to_delete = []
    @timeouts.each do |timeout|
      timeout.update
      if timeout.must_be_deleted?
        to_delete << timeout
      end
    end
    to_delete.each do |timeout|
      @timeouts.delete(timeout)
    end
  end

  class Timeout
    attr_accessor :delete
    def initialize(delay, type = :infinity, times = 1)
      @observer = nil
      @method = nil
      @delay = delay
      @counter = 0
      @type = type  # :once, :times, :infinity
      @times = times
      @stop = false
      @delete = false
    end

    def add_observer(observer, method)
      @observer = observer
      @method = method
    end

    def notify_observer
      @observer.send(@method)
    end

    def set_counter(value)
      @counter = value
      if @counter == @delay
        @counter = 0
        notify_observer

        if @type == :once
          stop
          @delete = true
          return
        end

        if @type == :times
          @times -= 1
          if @times <= 0
            stop
            @delete = true
            return
          end
        end
      end
    end

    def run
      @stop = false
    end

    def stop
      @stop = true
    end

    def delete
      @delete = true
    end

    def must_be_deleted?
      @delete
    end

    def update
      return unless @observer
      set_counter(@counter + 1) unless @stop
    end
  end
end
