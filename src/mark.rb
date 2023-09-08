require_relative 'constants'

include MiniGL

module Pusher
  def move_pushing(forces, stage, set_speed: false)
    delta_x = set_speed ? forces.x : @speed.x + forces.x / @mass
    move(forces, stage.obstacles.reject { |o| o == self }, [], set_speed)
    if delta_x > 0 && @right.is_a?(Mark)
      mark_speed_x = @right.push(@x + @w + delta_x - @right.x, stage)
      @x = @right.x - @w
      @speed.x = delta_x if mark_speed_x > 0
    elsif delta_x < 0 && @left.is_a?(Mark)
      mark_speed_x = @left.push(@x + delta_x - @left.x - @left.w, stage)
      @x = @left.x + @left.w
      @speed.x = delta_x if mark_speed_x < 0
    end
  end
end

class Mark < GameObject
  include Pusher

  def initialize(type, i, j)
    super(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE, type)
    @color = case type
             when :circle then 0xff3333cc
             else              0xffcc3333
             end
  end

  def passable
    false
  end

  def push(delta_x, stage)
    prev_speed = @speed.clone
    move_pushing(Vector.new(delta_x, 0), stage, set_speed: true)
    resulting_speed_x = @speed.x
    @speed = prev_speed
    resulting_speed_x
  end

  def update(stage)
    move_pushing(Vector.new, stage)
  end

  def draw
    super(nil, 1, 1, 255, @color)
  end
end
