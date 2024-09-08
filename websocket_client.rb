class WebSocketClient
  include Singleton
  attr_accessor :url, :ws, :identifier, :received_messages
  def initialize
    @url = "ws://localhost:3000/cable"
    @channel = {channel: "GameConnect"}
    @autorization = {
      login: 'qwerty',
      password: '12345'
    }
    @identifier = @channel.merge(@autorization).to_json
    @ws = nil
    @ws_thread = nil
    @received_messages = Queue.new
  end

  def connect
    @ws_thread = Thread.new do

      @ws = WebSocket::Client::Simple.connect(@url)

      current_self = self

      @ws.on :open do
        puts "!!!WebSocket connected!!!"

        data = {
          command: "subscribe",
          identifier: current_self.identifier,
        }.to_json
        current_self.ws.send(data)
      end

      @ws.on :message do |msg|
        data = JSON.parse(msg.data)
        if !current_self.is_system_message?(data)
          # pp data
          current_self.received_messages << data['message']
        end
      end

      @ws.on :close do |e|
        p "!!!Connection closed!!!"
      end

      @ws.on :error do |e|
        puts "!!!Error!!!: #{e.message}"
      end

      loop do
        sleep 0.1
      end

    end
  end

  def player_move(tile_x, tile_y)
    data = {
      command: "message",
      identifier: @identifier,
      data: {action: 'player_move', message: [tile_x, tile_y]}.to_json
    }.to_json
    @ws.send(data)
  end

  def create_projectile(owner_id:, target_id: nil, start_x:, start_y:, target_x:, target_y:, speed:, size:, map_name:)
    message = {
      owner_id: owner_id,
      target_id: target_id,
      start_x: start_x,
      start_y: start_y,
      target_x: target_x,
      target_y: target_y,
      speed: speed,
      size: size,
      map_name: map_name
    }

    data = {
      command: "message",
      identifier: @identifier,
      data: {action: 'create_projectile', message: message}.to_json
    }.to_json
    @ws.send(data)
  end

  def read_message
    begin
      return @received_messages.pop(true)
    rescue ThreadError
      return nil
    end
  end

  def is_system_message?(data)
    if (data['type'] == "welcome") || (data['type'] == "confirm_subscription") || (data['type'] == "ping")
      true
    else
      false
    end
  end
end


# URL = "ws://localhost:3000/cable"
# client = WebSocketClient.new(URL)
# client.connect
