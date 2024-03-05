require_relative 'level'

include MiniGL

class Game
  class << self
    attr_reader :font

    def init
      @font = Gosu::Font.new(24, name: "#{Res.prefix}font/DejaVuSans.ttf")
      @level_index = 6
      next_level
    end

    def next_level
      @level_index += 1
      @level = Level.new(@level_index)
      @level.on_finish = method(:on_level_finish)
    end

    def on_level_finish(result)
      if result == :victory
        next_level
      else
        @level.reset
      end
    end

    def update
      @level.update
    end

    def draw
      @level.draw
    end
  end
end
