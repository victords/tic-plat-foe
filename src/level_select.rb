require_relative 'constants'

include MiniGL

class LevelSelect
  class LevelThumbnail
    WIDTH = 120
    HEIGHT = 90
    T_TILE_SIZE = WIDTH / TILES_X
    T_SCALE = WIDTH.to_f / SCREEN_WIDTH

    def initialize(id, x, y)
      @x = x
      @y = y
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
    end

    def draw
      (0...TILES_X).each do |i|
        G.window.draw_rect(@x + i * T_TILE_SIZE, @y, 1, HEIGHT, GRID_COLOR, 0) if i > 0
        (0...TILES_Y).each do |j|
          G.window.draw_rect(@x, @y + j * T_TILE_SIZE, WIDTH, 1, GRID_COLOR, 0) if i == 0 && j > 0

          block = @blocks.any? { |(_i, _j)| _i == i && _j == j }
          block_rt = @blocks.any? { |(_i, _j)| _i == i + 1 && _j == j }
          block_dn = @blocks.any? { |(_i, _j)| _i == i && _j == j + 1 }
          rt = i < TILES_X - 1 && ((block && !block_rt) || (!block && block_rt))
          dn = j < TILES_Y - 1 && ((block && !block_dn) || (!block && block_dn))

          x = i * T_TILE_SIZE
          y = j * T_TILE_SIZE
          G.window.draw_rect(@x + x + T_TILE_SIZE, @y + y, 1, T_TILE_SIZE, WALL_COLOR, 0) if rt
          G.window.draw_rect(@x + x, @y + y + T_TILE_SIZE, T_TILE_SIZE, 1, WALL_COLOR, 0) if dn
        end
      end
      @passable_blocks.each do |(i, j)|
        G.window.draw_rect(@x + i * T_TILE_SIZE + 1, @y + j * T_TILE_SIZE, T_TILE_SIZE - 2, 1, WALL_COLOR, 0)
      end
      @marks.each do |(i, j, type)|
        color = 0xff000000 | MARK_COLOR[type]
        Res.img(type).draw(@x + i * T_TILE_SIZE, @y + j * T_TILE_SIZE, 0, T_SCALE, T_SCALE, color)
      end
      Res.img(:circle).draw(@x + @start_point[0] * T_TILE_SIZE, @y + @start_point[1] * T_TILE_SIZE, 0, T_SCALE, T_SCALE)
    end
  end

  def initialize
    @thumbnails = [LevelThumbnail.new(2, 50, 50)]
    @particles = Particles.new(
      x: 110,
      y: 95,
      img: Res.img(:levelThumb),
      scale_change: :grow,
      scale_min: 1,
      scale_max: 1.2,
      alpha_change: :shrink,
      emission_interval: 45,
      duration: 90
    ).start
  end

  def update
    @particles.update
  end

  def draw
    @thumbnails.each(&:draw)
    @particles.draw
  end
end
