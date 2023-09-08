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
    (4..6).each do |j|
      (13..14).each do |i|
        @blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
      end
    end
    @blocks << Block.new(3 * TILE_SIZE, 12 * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    @marks = [
      Mark.new(:circle, 10, 8),
      Mark.new(:circle, 10, 6),
      Mark.new(:circle, 10, 5),
      Mark.new(:circle, 14, 10),
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

  def update
    @character.update(self)
    marks_by_tile = Array.new(@map.size.x) { Array.new(@map.size.y) }
    @marks.each do |m|
      m.update(self)
      marks_by_tile[m.tile.x][m.tile.y] = m.type if m.tile
    end

    (0...@map.size.x).each do |i|
      last_type = nil
      last_count = 0
      (0...@map.size.y).each do |j|
        if marks_by_tile[i][j]
          if marks_by_tile[i][j] != last_type
            last_type = marks_by_tile[i][j]
            last_count = 1
          else
            last_count += 1
            if last_count == 3
              puts 'win'
            end
          end
        else
          last_type = nil
          last_count = 0
        end
      end
    end
    (0...@map.size.y).each do |j|
      last_type = nil
      last_count = 0
      (0...@map.size.x).each do |i|
        if marks_by_tile[i][j]
          if marks_by_tile[i][j] != last_type
            last_type = marks_by_tile[i][j]
            last_count = 1
          else
            last_count += 1
            if last_count == 3
              puts 'win'
            end
          end
        else
          last_type = nil
          last_count = 0
        end
      end
    end
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
