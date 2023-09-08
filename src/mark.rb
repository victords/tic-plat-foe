require_relative 'constants'
require_relative 'pusher'

include MiniGL

class Mark < GameObject
  include Pusher

  ROW_THRESHOLD = 1
  COLUMN_THRESHOLD = 4

  attr_reader :type, :tile

  def initialize(type, i, j)
    super(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE, type)
    @type = type
    @color = case type
             when :circle then 0x3333cc
             else              0xcc3333
             end
  end

  def push(delta_x, stage)
    prev_speed = @speed.clone
    move_pushing(Vector.new(delta_x, 0), stage, set_speed: true)
    resulting_speed_x = @speed.x
    @speed = prev_speed
    resulting_speed_x
  end

  def calculate_tile
    row = @y.to_i / TILE_SIZE
    delta_y = @y - row * TILE_SIZE
    if delta_y >= TILE_SIZE - ROW_THRESHOLD
      row += 1
    elsif delta_y > ROW_THRESHOLD
      return nil
    end

    column = @x.to_i / TILE_SIZE
    delta_x = @x - column.to_i * TILE_SIZE
    if delta_x >= TILE_SIZE - COLUMN_THRESHOLD
      column += 1
    elsif delta_x > COLUMN_THRESHOLD
      return nil
    end

    Vector.new(column, row)
  end

  def update(stage)
    move_pushing(Vector.new, stage)
    @tile = calculate_tile
  end

  def draw
    super(nil, 1, 1, @tile ? 255 : 127, @color)
  end
end
