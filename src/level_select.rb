require_relative 'constants'

include MiniGL

class LevelSelect
  L_S_TILES_X = 10
  L_S_TILES_Y = 10
  L_S_TILE_SIZE = 160
  THUMB_OFFSET_Y = 50
  CAM_SNAP_THRESHOLD = 2

  LEVELS_LAYOUT = [
    [2, 0],
    [2, 2],
    [4, 2],
    [6, 2],
    [6, 4],
    [6, 7],
  ].freeze

  attr_writer :on_select

  def initialize(last_level)
    @last_level = last_level

    @map = Map.new(L_S_TILE_SIZE, L_S_TILE_SIZE, L_S_TILES_X, L_S_TILES_Y)

    @elements = Array.new(L_S_TILES_X) { Array.new(L_S_TILES_Y) }
    @thumbnails = []
    LEVELS_LAYOUT[0...last_level].each_with_index do |(i, j), index|
      add_thumbnail(index + 1, i, j, index + 1 < last_level)
    end

    @cursor_pos = LEVELS_LAYOUT[0]
    @character = Character.new(@cursor_pos)
    level_under_cursor&.select
  end

  def last_level=(new_value)
    return unless new_value > @last_level

    @thumbnails[@last_level - 1].passed!
    @last_level = new_value
    (i, j) = LEVELS_LAYOUT[new_value - 1]
    add_thumbnail(new_value, i, j, false)
  end

  def update
    if @camera_target
      delta_x = @camera_target.x - @map.cam.x
      delta_y = @camera_target.y - @map.cam.y
      if delta_x.abs <= CAM_SNAP_THRESHOLD && delta_y.abs <= CAM_SNAP_THRESHOLD
        @map.set_camera(@camera_target.x, @camera_target.y)
        @camera_target = nil
      else
        @map.move_camera(delta_x * 0.2, delta_y * 0.2)
      end
    end

    if KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_SPACE)
      @on_select.call(level_under_cursor.id) if level_under_cursor
    elsif KB.key_pressed?(Gosu::KB_UP) && @cursor_pos[1] > 0
      move_cursor(:up)
    elsif KB.key_pressed?(Gosu::KB_RIGHT) && @cursor_pos[0] < L_S_TILES_X - 1
      move_cursor(:rt)
    elsif KB.key_pressed?(Gosu::KB_DOWN) && @cursor_pos[1] < L_S_TILES_Y - 1
      move_cursor(:dn)
    elsif KB.key_pressed?(Gosu::KB_LEFT) && @cursor_pos[0] > 0
      move_cursor(:lf)
    end

    @thumbnails.each(&:update)
    @character.update
  end

  def draw
    (1...L_S_TILES_X).each do |i|
      x = i * L_S_TILE_SIZE - 1 - @map.cam.x
      G.window.draw_rect(x, 0, 2, SCREEN_HEIGHT, GRID_COLOR, 0) if x >= -1 && x < SCREEN_WIDTH
    end
    (1...L_S_TILES_Y).each do |i|
      y = i * L_S_TILE_SIZE - 1 - @map.cam.y
      G.window.draw_rect(0, y, SCREEN_WIDTH, 2, GRID_COLOR, 0) if y >= -1 && y < SCREEN_HEIGHT
    end
    @thumbnails.each { |t| t.draw(@map) }
    @character.draw(@map)
  end

  private

  def add_thumbnail(level, i, j, passed)
    @elements[i][j] = LevelThumbnail.new(level,
                                         i * L_S_TILE_SIZE + (L_S_TILE_SIZE - LevelThumbnail::WIDTH) / 2,
                                         j * L_S_TILE_SIZE + THUMB_OFFSET_Y,
                                         passed)
    @thumbnails << @elements[i][j]
  end

  def level_under_cursor
    @elements[@cursor_pos[0]][@cursor_pos[1]]
  end

  def move_cursor(dir)
    level_under_cursor&.deselect
    case dir
    when :up
      @cursor_pos[1] -= 1
      @character.move(0, -1)
    when :rt
      @cursor_pos[0] += 1
      @character.move(1, 0)
    when :dn
      @cursor_pos[1] += 1
      @character.move(0, 1)
    else
      @cursor_pos[0] -= 1
      @character.move(-1, 0)
    end
    level_under_cursor&.select

    screen_pos = @map.get_screen_pos(*@cursor_pos)
    move_x = 0
    move_y = 0
    if screen_pos.x >= 4 * L_S_TILE_SIZE
      move_x = 2 * L_S_TILE_SIZE
    elsif screen_pos.x < L_S_TILE_SIZE
      move_x = -2 * L_S_TILE_SIZE
    end
    if screen_pos.y >= 3 * L_S_TILE_SIZE
      move_y = 2 * L_S_TILE_SIZE
    elsif screen_pos.y < L_S_TILE_SIZE
      move_y = -2 * L_S_TILE_SIZE
    end
    move_camera(move_x, move_y)
  end

  def move_camera(x, y)
    return if x.zero? && y.zero?

    target_x = (@camera_target&.x || @map.cam.x) + x
    target_x = [[target_x, 0].max, @map.instance_variable_get(:@max_x)].min
    target_y = (@camera_target&.y || @map.cam.y) + y
    target_y = [[target_y, 0].max, @map.instance_variable_get(:@max_y)].min
    return if target_x == @map.cam.x && target_y == @map.cam.y

    @camera_target = Vector.new(target_x, target_y)
  end

  class LevelThumbnail
    WIDTH = 120
    HEIGHT = 90
    T_TILE_SIZE = WIDTH / TILES_X
    T_SCALE = WIDTH.to_f / SCREEN_WIDTH

    attr_reader :id, :x, :y

    def initialize(id, x, y, passed)
      @id = id
      @x = x
      @y = y
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

  class Character
    include CharacterAnimation

    SCALE = 0.75

    def initialize(pos)
      @x = (pos[0] + 1) * L_S_TILE_SIZE - 50
      @y = pos[1] * L_S_TILE_SIZE + 7
      @img = Res.img(:circle)
      @w = SCALE * @img.width
      @h = SCALE * @img.height
      init_animation
    end

    def move(x, y)
      @target = Vector.new((@target&.x || @x) + x * L_S_TILE_SIZE, (@target&.y || @y) + y * L_S_TILE_SIZE)
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
          @x += delta_x * 0.2
          @y += delta_y * 0.2
        end
      end
      animate
    end

    def draw(map)
      @img.draw(@x + SCALE * @offset_x - map.cam.x,
                @y + SCALE * @offset_y - map.cam.y,
                0,
                SCALE * @scale_x,
                SCALE * @scale_y,
                0xffffffff)
    end
  end
end
