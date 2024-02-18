require_relative 'stage'

class Game
  class << self
    def init
      @stage_index = 0
      next_stage
    end

    def next_stage
      @stage_index += 1
      @stage = Stage.new(@stage_index)
      @stage.on_finish = method(:on_stage_finish)
    end

    def on_stage_finish(result)
      if result == :circle
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
