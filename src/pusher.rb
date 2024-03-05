module Pusher
  def move_pushing(forces, level, set_speed: false)
    delta_x = set_speed ? forces.x : @speed.x + forces.x / @mass
    delta_x = [[delta_x, -@max_speed.x].max, @max_speed.x].min

    move(forces, level.obstacles, [], set_speed)
    if delta_x > 0
      right_obstacles = find_obstacles(level.obstacles, false)
      return if right_obstacles.any? { |o| o.is_a?(Block) }
      return if right_obstacles.empty?

      new_x = @x + delta_x
      right_obstacles.each do |o|
        o.push(@x + @w + delta_x - o.x, level)
        new_x = o.x - @w if o.x - @w < new_x
      end
      if new_x > @x
        @x = new_x
        @speed.x = delta_x
      end
    elsif delta_x < 0
      left_obstacles = find_obstacles(level.obstacles, true)
      return if left_obstacles.any? { |o| o.is_a?(Block) }
      return if left_obstacles.empty?

      new_x = @x + delta_x
      left_obstacles.each do |o|
        o.push(@x + delta_x - o.x - o.w, level)
        new_x = o.x + o.w if o.x + o.w > new_x
      end
      if new_x < @x
        @x = new_x
        @speed.x = delta_x
      end
    end
  end

  private

  def find_obstacles(list, left)
    list.select do |o|
      @y + @h > o.y && o.y + o.h > @y && o.x == (left ? @x - o.w : @x + @w)
    end
  end
end
