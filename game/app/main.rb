require 'lib/minigl'
require 'app/text'
require 'app/game'

def tick(args)
  if args.state.tick_count == 0
    G.initialize(fullscreen: false)
    Text.init
    Game.init
  end

  Game.update

  Window.begin_draw
  Game.draw
  Window.end_draw
end
