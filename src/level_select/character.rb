require_relative '../constants'

module LevelSelect
  class Character
    include CharacterAnimation

    SCALE = 0.75

    def initialize(pos)
      @x = (pos[0] + 1) * TILE_SIZE - 12
      @y = pos[1] * TILE_SIZE + 2
      @img = Res.img(:circle)
      @w = SCALE * @img.width
      @h = SCALE * @img.height
      init_animation
    end

    def move(x, y)
      @target = Vector.new((@target&.x || @x) + x * TILE_SIZE, (@target&.y || @y) + y * TILE_SIZE)
    end

    def update
      if @target
        delta_x = @target.x - @x
        delta_y = @target.y - @y
        if delta_x.abs < 0.1 && delta_y.abs < 0.1
          @x = @target.x
          @y = @target.y
          @target = nil
        else
          @x += delta_x * INTERPOLATION_RATE
          @y += delta_y * INTERPOLATION_RATE
        end
      end
      animate
    end

    def draw(map, zoom)
      @img.draw(zoom * (@x + SCALE * @offset_x) - map.cam.x,
                zoom * (@y + SCALE * @offset_y) - map.cam.y,
                0,
                SCALE * @scale_x,
                SCALE * @scale_y,
                0xffffffff)
    end
  end
end
