require_relative 'stage'

class Game
  class << self
    def init
      @stage = Stage.new(1)
      @stage.start
    end

    def update
      @stage.update
    end

    def draw
      @stage.draw
    end
  end
end
