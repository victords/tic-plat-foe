require_relative 'text'
require_relative 'game'

include MiniGL

class TicPlatFoe < GameWindow
  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    self.caption = "Tic-plat-foe"
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Text.init
    Game.init
  end

  def needs_cursor?
    false
  end

  def update
    KB.update
    Game.update
  end

  def draw
    Game.draw
  end
end

TicPlatFoe.new.show
