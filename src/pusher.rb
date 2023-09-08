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
