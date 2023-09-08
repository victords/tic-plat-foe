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
    @marks.each { |m| m.update(self) }
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
