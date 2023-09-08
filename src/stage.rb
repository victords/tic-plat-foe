require 'minigl'
require_relative 'character'

include MiniGL

class Stage
  attr_reader :obstacles

  def initialize
    @map = Map.new(TILE_SIZE, TILE_SIZE, SCREEN_WIDTH / TILE_SIZE, SCREEN_HEIGHT / TILE_SIZE, SCREEN_WIDTH, SCREEN_HEIGHT)
    @obstacles = [
      Block.new(-1, 0, 1, SCREEN_HEIGHT),
      Block.new(SCREEN_WIDTH, 0, 1, SCREEN_HEIGHT),
    ]
    (13..15).each do |j|
      (0..19).each do |i|
        @obstacles << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
      end
    end
    (4..6).each do |j|
      (13..14).each do |i|
        @obstacles << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
      end
    end
    @obstacles << Block.new(3 * TILE_SIZE, 12 * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    @character = Character.new
  end

  def update
    @character.update(self)
  end

  def draw
    @map.foreach do |i, j, x, y|
      obst = @obstacles.any? { |o| o.x == x && o.y == y }
      obst_rt = @obstacles.any? { |o| o.x == x + TILE_SIZE && o.y == y }
      obst_dn = @obstacles.any? { |o| o.x == x && o.y == y + TILE_SIZE }
      rt = i < @map.size.x - 1 && ((obst && !obst_rt) || (!obst && obst_rt))
      dn = j < @map.size.y - 1 && ((obst && !obst_dn) || (!obst && obst_dn))
      G.window.draw_rect(x + TILE_SIZE - 1, y, 2, TILE_SIZE, 0xffffffff, 0) if rt
      G.window.draw_rect(x, y + TILE_SIZE - 1, TILE_SIZE, 2, 0xffffffff, 0) if dn
    end
    @character.draw
  end
end
