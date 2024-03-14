require_relative 'character'
require_relative 'mark'
require_relative 'effect/tile_highlight_effect'
require_relative 'effect/level_end_effect'

include MiniGL

class Level
  attr_reader :marks
  attr_writer :on_finish

  def initialize(id)
    @id = id
    @map = Map.new(TILE_SIZE, TILE_SIZE, TILES_X, TILES_Y, SCREEN_WIDTH, SCREEN_HEIGHT)
    @blocks = [
      Block.new(-1, 0, 1, SCREEN_HEIGHT),
      Block.new(SCREEN_WIDTH, 0, 1, SCREEN_HEIGHT),
    ]
    @passable_blocks = []
    @marks = []
    @effects = []
    @character = Character.new

    File.open("#{Res.prefix}level/#{id}") do |f|
      contents = f.read
      first_line_break = contents.index("\n")
      @title = contents[0...first_line_break]

      i = 0
      j = 0
      effect_index = 0
      contents[(first_line_break + 1)..].each_line do |line|
        line.each_char do |char|
          case char
          when 's'
            @start_point = Vector.new(i, j)
            @character.move_to(@start_point.x, @start_point.y)
          when '#'
            @blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
          when '-'
            @passable_blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE, true)
          when 'o', 'O'
            @marks << Mark.new(:circle, i, j)
            effect_index = add_highlight_effect(i, j, effect_index) if char == 'O'
          when 'x', 'X'
            @marks << Mark.new(:x, i, j)
            effect_index = add_highlight_effect(i, j, effect_index) if char == 'X'
          when '['
            @marks << Mark.new(:square, i, j)
          when '*'
            effect_index = add_highlight_effect(i, j, effect_index)
          end
          i += 1
        end
        j += 1
        i = 0
      end
    end

    @drawable_walls = []
    @map.foreach do |i, j, x, y|
      block = @blocks.any? { |o| o.x == x && o.y == y }
      block_rt = @blocks.any? { |o| o.x == x + TILE_SIZE && o.y == y }
      block_dn = @blocks.any? { |o| o.x == x && o.y == y + TILE_SIZE }
      rt = i < @map.size.x - 1 && ((block && !block_rt) || (!block && block_rt))
      dn = j < @map.size.y - 1 && ((block && !block_dn) || (!block && block_dn))
      @drawable_walls << [x, y, true] if rt
      @drawable_walls << [x, y, false] if dn
    end
  end

  def reset
    @character.move_to(@start_point.x, @start_point.y)
    @marks.each(&:reset)
    @effects.clear
    @finished = nil
  end

  def obstacles
    @blocks + @passable_blocks + @marks + [@character]
  end

  def add_highlight_effect(i, j, index)
    @effects << TileHighlightEffect.new(i, j, index)
    index + 1
  end

  def add_effect(effect)
    @effects << effect
  end

  def check_combo(marks_by_tile)
    marks_by_tile.flatten.compact.each do |mark|
      # left to right
      i0 = [mark.tile.x - 2, 0].max
      i1 = [mark.tile.x + 2, @map.size.x - 1].min - 2
      (i0..i1).each do |i|
        if marks_by_tile[i][mark.tile.y]&.type == marks_by_tile[i + 1][mark.tile.y]&.type &&
           marks_by_tile[i][mark.tile.y]&.type == marks_by_tile[i + 2][mark.tile.y]&.type
          return mark.type
        end
      end

      # top to bottom
      j0 = [mark.tile.y - 2, 0].max
      j1 = [mark.tile.y + 2, @map.size.y - 1].min - 2
      (j0..j1).each do |j|
        if marks_by_tile[mark.tile.x][j]&.type == marks_by_tile[mark.tile.x][j + 1]&.type &&
           marks_by_tile[mark.tile.x][j]&.type == marks_by_tile[mark.tile.x][j + 2]&.type
          return mark.type
        end
      end

      # top-left to bottom-right
      steps_left = [[mark.tile.x, mark.tile.y].min, 2].min
      i0 = mark.tile.x - steps_left
      j0 = mark.tile.y - steps_left
      steps_right = [[@map.size.x - 1 - mark.tile.x, @map.size.y - 1 - mark.tile.y].min, 2].min
      i1 = mark.tile.x + steps_right - 2
      (i0..i1).each_with_index do |i, index|
        if marks_by_tile[i][j0 + index]&.type == marks_by_tile[i + 1][j0 + index + 1]&.type &&
           marks_by_tile[i][j0 + index]&.type == marks_by_tile[i + 2][j0 + index + 2]&.type
          return mark.type
        end
      end

      # bottom-left to top-right
      steps_left = [[mark.tile.x, @map.size.y - 1 - mark.tile.y].min, 2].min
      i0 = mark.tile.x - steps_left
      j0 = mark.tile.y + steps_left
      steps_right = [[@map.size.x - 1 - mark.tile.x, mark.tile.y].min, 2].min
      i1 = mark.tile.x + steps_right - 2
      (i0..i1).each_with_index do |i, index|
        if marks_by_tile[i][j0 - index]&.type == marks_by_tile[i + 1][j0 - index - 1]&.type &&
           marks_by_tile[i][j0 - index]&.type == marks_by_tile[i + 2][j0 - index - 2]&.type
          return mark.type
        end
      end
    end
    nil
  end

  def update
    unless @finished
      reset if KB.key_pressed?(Gosu::KB_R)

      @character.update(self)

      marks_by_tile = Array.new(@map.size.x) { Array.new(@map.size.y) }
      @marks.each do |m|
        m.update(self)
        marks_by_tile[m.tile.x][m.tile.y] = m if m.tile && m.circle_or_x?
      end
    end

    finished = @finished
    @effects.reverse_each do |e|
      e.update
      if e.dead
        @effects.delete(e)
        @on_finish.call(finished) if e.is_a?(LevelEndEffect)
      end
    end
    return if finished

    mark_type = check_combo(marks_by_tile)
    if mark_type
      result = mark_type == :circle ? :victory : :defeat
      add_effect(LevelEndEffect.new(result))
      @finished = result
    end
  end

  def draw
    (1...@map.size.x).each do |i|
      G.window.draw_rect(i * TILE_SIZE - 1, 0, 2, SCREEN_HEIGHT, GRID_COLOR, 0)
    end
    (1...@map.size.y).each do |j|
      G.window.draw_rect(0, j * TILE_SIZE - 1, SCREEN_WIDTH, 2, GRID_COLOR, 0)
    end

    @drawable_walls.each do |(x, y, rt)|
      if rt
        G.window.draw_rect(x + TILE_SIZE - 1, y, 2, TILE_SIZE, WALL_COLOR, 0)
      else
        G.window.draw_rect(x, y + TILE_SIZE - 1, TILE_SIZE, 2, WALL_COLOR, 0)
      end
    end

    @passable_blocks.each do |b|
      G.window.draw_rect(b.x + 4, b.y - 1, TILE_SIZE - 8, 2, WALL_COLOR, 0)
    end
    @marks.each(&:draw)
    @character.draw
    @effects.each(&:draw)

    Game.font.draw_text("Level #{@id}", 10, 5, 0, 0.75, 0.75, 0x99ffffff)
    Game.font.draw_text(@title, 10, 28, 0, 1, 1, 0xffffffff)
  end
end
