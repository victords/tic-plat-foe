require_relative '../constants'

class Transition
  SCALE_DURATION = 15
  STEP_DURATION = (TILES_X + TILES_Y - 1) + SCALE_DURATION
  COLOR = 0xffffffff

  attr_reader :dead

  def initialize(&callback)
    @timer = 0
    @callback = callback
  end

  def update
    return if @dead

    @timer += 1
    if @timer >= 2 * STEP_DURATION
      @dead = true
    elsif @timer == STEP_DURATION
      @callback.call
    end
  end

  def draw
    (0...TILES_X).each do |i|
      (0...TILES_Y).each do |j|
        delay = i + j
        next if @timer < delay

        frame = @timer - delay
        frame -= STEP_DURATION if @timer >= STEP_DURATION

        scale = [frame.to_f / SCALE_DURATION, 1].min
        scale = 1 - scale if @timer >= STEP_DURATION
        size = TILE_SIZE * scale
        G.window.draw_rect(i * TILE_SIZE + (TILE_SIZE - size) / 2, j * TILE_SIZE + (TILE_SIZE - size) / 2, size, size, COLOR, 1000)
      end
    end
  end
end
