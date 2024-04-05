require_relative '../constants'

module LevelSelect
  class Thumbnail
    WIDTH = 120
    HEIGHT = 90
    THUMB_OFFSET_Y = 50
    T_TILE_SIZE = WIDTH / TILES_X
    T_SCALE = WIDTH.to_f / SCREEN_WIDTH

    attr_reader :id, :x, :y

    def initialize(id, col, row, passed)
      @id = id
      @x = col * L_S_TILE_SIZE + (L_S_TILE_SIZE - WIDTH) / 2
      @y = row * L_S_TILE_SIZE + THUMB_OFFSET_Y
      @passed = passed
      @blocks = []
      @passable_blocks = []
      @marks = []

      File.open("#{Res.prefix}level/#{id}") do |f|
        contents = f.read
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
        source: self,
        source_offset_x: WIDTH / 2,
        source_offset_y: HEIGHT / 2,
        img: Res.img(:levelThumb),
        scale_change: :grow,
        scale_min: 1,
        scale_max: 1.2,
        alpha_change: :shrink,
        emission_interval: 30,
        duration: 45
      )
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

    def update
      @selection.update
    end

    def draw(map)
      cam_x = map.cam.x
      cam_y = map.cam.y

      Text.write("Level #{@id}", @x - cam_x, @y - THUMB_OFFSET_Y + 10 - cam_y)

      (1...TILES_X).each do |i|
        G.window.draw_rect(@x + i * T_TILE_SIZE - cam_x, @y - cam_y, 1, HEIGHT, GRID_COLOR, 0)
      end
      (1...TILES_Y).each do |j|
        G.window.draw_rect(@x - cam_x, @y + j * T_TILE_SIZE - cam_y, WIDTH, 1, GRID_COLOR, 0)
      end
      @drawable_walls.each do |(x, y, rt)|
        if rt
          G.window.draw_rect(@x + x + T_TILE_SIZE - cam_x, @y + y - cam_y, 1, T_TILE_SIZE, WALL_COLOR, 0)
        else
          G.window.draw_rect(@x + x - cam_x, @y + y + T_TILE_SIZE - cam_y, T_TILE_SIZE, 1, WALL_COLOR, 0)
        end
      end
      @passable_blocks.each do |(i, j)|
        G.window.draw_rect(@x + i * T_TILE_SIZE + 1 - cam_x, @y + j * T_TILE_SIZE - cam_y, T_TILE_SIZE - 2, 1, WALL_COLOR, 0)
      end
      @marks.each do |(i, j, type)|
        color = 0xff000000 | MARK_COLOR[type]
        Res.img(type).draw(@x + i * T_TILE_SIZE - cam_x, @y + j * T_TILE_SIZE - cam_y, 0, T_SCALE, T_SCALE, color)
      end

      circle = Res.img(:circle)
      circle.draw(@x + @start_point[0] * T_TILE_SIZE - cam_x, @y + @start_point[1] * T_TILE_SIZE - cam_y, 0, T_SCALE, T_SCALE)
      if @passed
        circle.draw(@x + (WIDTH - 2 * circle.width) / 2 - cam_x,
                    @y + (HEIGHT - 2 * circle.height) / 2 - cam_y,
                    0, 2, 2, (0x66 << 24) | MARK_COLOR[:circle])
      end

      @selection.draw(map)
    end
  end
end
