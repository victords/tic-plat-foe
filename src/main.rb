require 'minigl'
require_relative 'constants'
require_relative 'game'

include MiniGL

class TicPlatFoe < GameWindow
  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Game.init
  end

  def update
    Mouse.update
    KB.update
    Game.update
  end

  def draw
    Game.draw
  end
end

TicPlatFoe.new.show
