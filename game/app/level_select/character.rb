require 'app/constants'

module LevelSelect
  class Character
    include CharacterAnimation

    SCALE = 0.75
    FADE_DURATION = 30
    MOVE_INTERPOLATION_RATE = 0.2

    attr_writer :on_fade_end

    def initialize(col, row)
      move_to_zoomed_in(col, row)
      @img = Image.new(:circle)
      @w = SCALE * @img.width
      @h = SCALE * @img.height
      @alpha = 255
      init_animation
    end

    def move(x, y)
      @target = Vector.new((@target&.x || @x) + x * TILE_SIZE, (@target&.y || @y) + y * TILE_SIZE)
    end

    def move_to_zoomed_in(col, row)
      @x = (col + 1) * TILE_SIZE - 12
      @y = row * TILE_SIZE + 2
    end

    def move_to_zoomed_out(col, row)
      @x = col * TILE_SIZE + (TILE_SIZE - @w) / 2
      @y = row * TILE_SIZE + (TILE_SIZE - @h) / 2
    end

    def fade(in_out)
      @fade = in_out
      @timer = 0
    end

    def update
      if @fade
        @timer += 1
        rate = @timer.to_f / FADE_DURATION
        @alpha = (255 * (@fade == :in ? rate : 1 - rate)).round
        if @timer >= FADE_DURATION
          @on_fade_end&.call if @fade == :out
          @fade = nil
        end
      end

      if @target
        delta_x = @target.x - @x
        delta_y = @target.y - @y
        if delta_x.abs < 0.1 && delta_y.abs < 0.1
          @x = @target.x
          @y = @target.y
          @target = nil
        else
          @x += delta_x * MOVE_INTERPOLATION_RATE
          @y += delta_y * MOVE_INTERPOLATION_RATE
        end
      end
      animate
    end

    def draw(map, zoom)
      @img.draw(zoom * @x + SCALE * @offset_x - map.cam.x,
                zoom * @y + SCALE * @offset_y - map.cam.y,
                scale_x: SCALE * @scale_x,
                scale_y: SCALE * @scale_y,
                color: (@alpha << 24) | 0xffffff)
    end
  end
end
