require_relative 'constants'
require_relative 'pusher'

include MiniGL

class Mark < GameObject
  include Pusher

  ROW_THRESHOLD = 1
  COLUMN_THRESHOLD = 6

  attr_reader :type, :tile

  def initialize(type, i, j)
    super(i * TILE_SIZE + 1, j * TILE_SIZE, TILE_SIZE - 2, TILE_SIZE, type, Vector.new(-1, 0))
    @start_x = @x
    @start_y = @y
    @type = type
    @color = MARK_COLOR[type]
  end

  def push(delta_x, level)
    prev_speed = @speed.clone
    move_pushing(Vector.new(delta_x, 0), level, set_speed: true)
    @speed = prev_speed
  end

  def circle_or_x?
    type == :circle || type == :x
  end

  def reset
    @speed = Vector.new
    @x = @start_x
    @y = @start_y
    @tile = nil
  end

  def update(level)
    move(Vector.new, level.obstacles, [])
    @tile = calculate_tile
  end

  def draw
    alpha = if circle_or_x?
              @tile ? 255 : 127
            else
              255
            end
    super(nil, 1, 1, alpha, @color)
  end

  private

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
end
