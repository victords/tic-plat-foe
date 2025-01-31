require 'app/level'
require 'app/level_select/map'
require 'app/effect/transition'

class Game
  class << self
    def init
      @last_level = 6
      @level_select = LevelSelect::Map.new(@last_level)
      @level_select.on_select = method(:on_level_select)
    end

    def on_level_select(id)
      @level_index = id - 1
      next_level
    end

    def on_level_finish(result)
      if result == :victory
        if @level_index == @last_level
          @last_level += 1
          @level_select.last_level = @last_level
          next_level
        else
          back_to_level_select
        end
      else
        @level.reset
      end
    end

    def next_level
      @level_index += 1
      @transition = Transition.new do
        @level = Level.new(@level_index)
        @level.on_finish = method(:on_level_finish)
      end
    end

    def back_to_level_select
      @transition = Transition.new do
        @level = nil
      end
    end

    def update
      KB.update
      if @transition
        @transition.update
        @transition = nil if @transition.dead
      end
      if @level
        @level.update
      else
        @level_select.update
      end
    end

    def draw
      Window.draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0xff000000, -1000)
      @transition&.draw
      if @level
        @level.draw
      else
        @level_select.draw
      end
    end
  end
end
