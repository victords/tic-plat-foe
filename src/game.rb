require_relative 'level'
# require_relative 'level_select'

include MiniGL

class Game
  class << self
    attr_reader :font

    def init
      @font = Gosu::Font.new(24, name: "#{Res.prefix}font/DejaVuSans.ttf")
      @level_index = 0
      # @level_select = LevelSelect.new
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
      # @level_select.update
    end

    def draw
      @level.draw
      # @level_select.draw
    end
  end
end
