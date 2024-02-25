require_relative 'stage'

include MiniGL

class Game
  class << self
    attr_reader :font

    def init
      @font = Gosu::Font.new(24, name: "#{Res.prefix}font/DejaVuSans.ttf")
      @stage_index = 0
      next_stage
    end

    def next_stage
      @stage_index += 1
      @stage = Stage.new(@stage_index)
      @stage.on_finish = method(:on_stage_finish)
    end

    def on_stage_finish(result)
      if result == :victory
        next_stage
      else
        @stage.reset
      end
    end

    def update
      @stage.update
    end

    def draw
      @stage.draw
    end
  end
end
