require_relative 'level'
require_relative 'level_select'
require_relative 'effect/transition'

include MiniGL

class Game
  class << self
    def init
      @level_select = LevelSelect.new
      @level_select.on_select = method(:on_level_select)
    end

    def on_level_select(id)
      @level_index = id - 1
      next_level
    end

    def on_level_finish(result)
      if result == :victory
        next_level
      else
        @level.reset
      end
    end

    def next_level
      @transition = Transition.new do
        @level_index += 1
        @level = Level.new(@level_index)
        @level.on_finish = method(:on_level_finish)
      end
    end

    def update
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
      @transition&.draw
      if @level
        @level.draw
      else
        @level_select.draw
      end
    end
  end
end
