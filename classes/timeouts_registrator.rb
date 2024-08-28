class TimeoutsRegistrator
  include Singleton
  def initialize
    @timeouts = []
  end

  def add_timeout(observer:, method:, delay:, type: :infinity)
    timeout = Timeout.new(delay, type)
    timeout.add_observer(observer, method)
    @timeouts.push(timeout)
    return timeout
  end

  def remove_timeout(timeout)
    @timeouts.delete(timeout)
  end

  def update
    to_delete = []
    @timeouts.each do |timeout|
      timeout.update
      timeout << to_delete if timeout.to_delete?
    end
    to_delete.each { |timeout| @timeouts.delete(timeout) }
  end
end

class Timeout
  include Observable

  attr_accessor :to_delete?
  def initialize(delay, type = :infinity)
    @delay = delay
    @counter = 0
    @stop = false
    @type = type
    @to_delete? = false
  end

  def counter=(value)
    @counter = value
    if @counter == @delay
      @counter = 0
      changed
      notify_observers

      if @type == :once
        stop
        @to_delete? = true
      end
    end
  end

  def run
    @stop = false
  end

  def stop
    @stop = true
  end

  def update
    counter = @counter + 1 unless @stop
  end
end
