require 'app/constants'

class TileHighlightEffect
  INTERVAL = 300
  DURATION = 90
  COLOR = 0x00ffff

  def initialize(i, j, index)
    @x = i * TILE_SIZE + 1
    @y = j * TILE_SIZE + 1
    @timer = INTERVAL - index * 15
    @alpha = 0
  end

  def dead; false; end

  def update
    @timer += 1
    if @timer > INTERVAL
      frame = @timer - INTERVAL
      @alpha = (85 * (1 - ((frame - DURATION).to_f / DURATION).abs)).round
      @timer = 0 if frame >= 2 * DURATION
    end
  end

  def draw
    color = (@alpha << 24) | COLOR
    Window.draw_rect(@x, @y, TILE_SIZE - 2, TILE_SIZE - 2, color)
  end
end
