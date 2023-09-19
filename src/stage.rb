require 'minigl'
require_relative 'character'
require_relative 'mark'

include MiniGL

class Stage
  GRID_COLOR = 0x33ffffff
  WALL_COLOR = 0xffffffff

  attr_reader :marks

  def initialize
    @map = Map.new(TILE_SIZE, TILE_SIZE, SCREEN_WIDTH / TILE_SIZE, SCREEN_HEIGHT / TILE_SIZE, SCREEN_WIDTH, SCREEN_HEIGHT)
    @blocks = [
      Block.new(-1, 0, 1, SCREEN_HEIGHT),
      Block.new(SCREEN_WIDTH, 0, 1, SCREEN_HEIGHT),
    ]
    (13..15).each do |j|
      (0..19).each do |i|
        @blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
      end
    end
    @blocks << Block.new(11 * TILE_SIZE, 12 * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    @blocks << Block.new(10 * TILE_SIZE, 11 * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    @blocks << Block.new(10 * TILE_SIZE, 12 * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    @marks = [
      Mark.new(:circle, 10, 0),
      Mark.new(:circle, 11, 0),
      Mark.new(:circle, 12, 0),
    ]
    @character = Character.new
    @start_point = Vector.new(2, 12)
  end

  def start
    @character.move_to(@start_point.x, @start_point.y)
  end

  def obstacles
    @blocks + @marks + [@character]
  end

  def check_victory(marks_by_tile)
    marks_by_tile.flatten.compact.each do |mark|
      # left to right
      i0 = [mark.tile.x - 2, 0].max
      i1 = [mark.tile.x + 2, @map.size.x - 1].min - 2
      (i0..i1).each do |i|
        if marks_by_tile[i][mark.tile.y]&.type == marks_by_tile[i + 1][mark.tile.y]&.type &&
           marks_by_tile[i][mark.tile.y]&.type == marks_by_tile[i + 2][mark.tile.y]&.type
          return :lr
        end
      end

      # top to bottom
      j0 = [mark.tile.y - 2, 0].max
      j1 = [mark.tile.y + 2, @map.size.y - 1].min - 2
      (j0..j1).each do |j|
        if marks_by_tile[mark.tile.x][j]&.type == marks_by_tile[mark.tile.x][j + 1]&.type &&
           marks_by_tile[mark.tile.x][j]&.type == marks_by_tile[mark.tile.x][j + 2]&.type
          return :tb
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
          return :d1
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
          return :d2
        end
      end
    end
    nil
  end

  def update
    @character.update(self)
    marks_by_tile = Array.new(@map.size.x) { Array.new(@map.size.y) }
    @marks.each do |m|
      m.update(self)
      marks_by_tile[m.tile.x][m.tile.y] = m if m.tile
    end
    puts check_victory(marks_by_tile)
  end

  def draw
    (1...@map.size.x).each do |i|
      G.window.draw_rect(i * TILE_SIZE - 1, 0, 2, SCREEN_HEIGHT, GRID_COLOR, 0)
    end
    (1...@map.size.y).each do |j|
      G.window.draw_rect(0, j * TILE_SIZE - 1, SCREEN_WIDTH, 2, GRID_COLOR, 0)
    end
    @map.foreach do |i, j, x, y|
      block = @blocks.any? { |o| o.x == x && o.y == y }
      block_rt = @blocks.any? { |o| o.x == x + TILE_SIZE && o.y == y }
      block_dn = @blocks.any? { |o| o.x == x && o.y == y + TILE_SIZE }
      rt = i < @map.size.x - 1 && ((block && !block_rt) || (!block && block_rt))
      dn = j < @map.size.y - 1 && ((block && !block_dn) || (!block && block_dn))
      G.window.draw_rect(x + TILE_SIZE - 1, y, 2, TILE_SIZE, WALL_COLOR, 0) if rt
      G.window.draw_rect(x, y + TILE_SIZE - 1, TILE_SIZE, 2, WALL_COLOR, 0) if dn
    end
    @marks.each(&:draw)
    @character.draw
  end
end
