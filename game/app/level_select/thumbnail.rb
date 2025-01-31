require 'app/constants'

module LevelSelect
  class Thumbnail
    ZOOMED_IN_WIDTH = 120
    ZOOMED_IN_HEIGHT = 90
    THUMB_OFFSET_X = (L_S_MAX_ZOOM * TILE_SIZE - ZOOMED_IN_WIDTH) / 2
    THUMB_OFFSET_Y = 50
    T_TILE_SIZE = ZOOMED_IN_WIDTH / TILES_X
    T_SCALE = ZOOMED_IN_WIDTH.to_f / SCREEN_WIDTH
    FADE_DURATION = 30

    attr_reader :id, :x, :y
    attr_writer :on_fade_end

    def initialize(id, col, row, passed)
      @id = id
      @x = col * TILE_SIZE
      @y = row * TILE_SIZE
      @passed = passed
      @blocks = []
      @passable_blocks = []
      @marks = []

      $gtk.read_file("data/level/#{id}").tap do |contents|
        first_line_break = contents.index("\n")
        @title = contents[0...first_line_break]

        i = 0
        j = 0
        contents[(first_line_break + 1)..].each_line do |line|
          line.each_char do |char|
            case char
            when 's'
              @start_point = [i, j]
            when '#'
              @blocks << [i, j]
            when '-'
              @passable_blocks << [i, j]
            when 'o', 'O'
              @marks << [i, j, :circle]
            when 'x', 'X'
              @marks << [i, j, :x]
            when '['
              @marks << [i, j, :square]
            end
            i += 1
          end
          j += 1
          i = 0
        end
      end

      @drawable_walls = []
      (0...TILES_X).each do |i|
        (0...TILES_Y).each do |j|
          block = @blocks.any? { |(_i, _j)| _i == i && _j == j }
          block_rt = @blocks.any? { |(_i, _j)| _i == i + 1 && _j == j }
          block_dn = @blocks.any? { |(_i, _j)| _i == i && _j == j + 1 }
          rt = i < TILES_X - 1 && ((block && !block_rt) || (!block && block_rt))
          dn = j < TILES_Y - 1 && ((block && !block_dn) || (!block && block_dn))

          x = i * T_TILE_SIZE
          y = j * T_TILE_SIZE
          @drawable_walls << [x, y, true] if rt
          @drawable_walls << [x, y, false] if dn
        end
      end

      @selection = Particles.new(
        x: L_S_MAX_ZOOM * (@x + TILE_SIZE / 2),
        y: L_S_MAX_ZOOM * @y + THUMB_OFFSET_Y + ZOOMED_IN_HEIGHT / 2,
        img: Image.new(:levelThumb),
        scale_change: :grow,
        scale_min: 1,
        scale_max: 1.2,
        alpha_change: :shrink,
        emission_interval: 30,
        duration: 45
      )

      @thumb_alpha = 255
      @abbrev_alpha = 0
    end

    def select
      @selection.start
    end

    def deselect
      @selection.stop
    end

    def passed!
      @passed = true
    end

    def fade(in_out)
      @selection.stop
      @fade = in_out
      @timer = 0
    end

    def update
      if @fade
        @timer += 1
        rate = @timer.to_f / FADE_DURATION
        @thumb_alpha = (255 * (@fade == :in ? rate : 1 - rate)).round
        @abbrev_alpha = (255 * (@fade == :in ? 1 - rate : rate)).round
        if @timer >= FADE_DURATION
          @fade = nil
          @on_fade_end&.call
        end
      end
      @selection.update
    end

    def draw(map, zoom)
      cam_x = map.cam.x
      cam_y = map.cam.y
      circle = Image.new(:circle)

      if @thumb_alpha > 0
        base_x = zoom * @x + THUMB_OFFSET_X
        base_y = zoom * @y + THUMB_OFFSET_Y
        Text.write("Level #{@id}", base_x - cam_x, base_y - THUMB_OFFSET_Y + 10 - cam_y, 1, DEFAULT_TEXT_COLOR, @thumb_alpha)

        grid_color = ((0.2 * @thumb_alpha).round << 24) | (GRID_COLOR & 0xffffff)
        (1...TILES_X).each do |i|
          Window.draw_rect(base_x + i * T_TILE_SIZE - cam_x, base_y - cam_y, 1, ZOOMED_IN_HEIGHT, grid_color, 0)
        end
        (1...TILES_Y).each do |j|
          Window.draw_rect(base_x - cam_x, base_y + j * T_TILE_SIZE - cam_y, ZOOMED_IN_WIDTH, 1, grid_color, 0)
        end

        wall_color = (@thumb_alpha << 24) | (WALL_COLOR & 0xffffff)
        @drawable_walls.each do |(x, y, rt)|
          if rt
            Window.draw_rect(base_x + x + T_TILE_SIZE - cam_x, base_y + y - cam_y, 1, T_TILE_SIZE, wall_color, 0)
          else
            Window.draw_rect(base_x + x - cam_x, base_y + y + T_TILE_SIZE - cam_y, T_TILE_SIZE, 1, wall_color, 0)
          end
        end
        @passable_blocks.each do |(i, j)|
          Window.draw_rect(base_x + i * T_TILE_SIZE + 1 - cam_x, base_y + j * T_TILE_SIZE - cam_y, T_TILE_SIZE - 2, 1, wall_color, 0)
        end

        @marks.each do |(i, j, type)|
          color = (@thumb_alpha << 24) | MARK_COLOR[type]
          Image.new(type).draw(base_x + i * T_TILE_SIZE - cam_x, base_y + j * T_TILE_SIZE - cam_y, scale_x: T_SCALE, scale_y: T_SCALE, color: color)
        end

        circle.draw(base_x + @start_point[0] * T_TILE_SIZE - cam_x,
                    base_y + @start_point[1] * T_TILE_SIZE - cam_y,
                    scale_x: T_SCALE, scale_y: T_SCALE, color: (@thumb_alpha << 24) | 0xffffff)
      end

      if @abbrev_alpha > 0
        Text.write_center("L#{@id}", zoom * (@x + TILE_SIZE / 2) - cam_x, zoom * (@y + TILE_SIZE / 2) - cam_y, 2, DEFAULT_TEXT_COLOR, @abbrev_alpha)
      end

      if @passed
        rate = (zoom - 1) / (L_S_MAX_ZOOM - 1)
        scale = 1 + rate
        alpha = 204 - (rate * 102).round
        circle.draw(zoom * (@x + (TILE_SIZE - scale.to_f / zoom * circle.width) / 2) - cam_x,
                    zoom * (@y + (TILE_SIZE - scale.to_f / zoom * circle.height) / 2) - cam_y,
                    scale_x: scale, scale_y: scale, color: (alpha << 24) | MARK_COLOR[:circle])
      end

      @selection.draw(map)
    end
  end
end
