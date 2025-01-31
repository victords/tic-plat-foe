class Map
  SQRT_2_DIV_2 = Math.sqrt(2) / 2
  MINUS_PI_DIV_4 = -Math::PI / 4

  attr_reader :tile_size, :size, :cam

  def initialize(t_w, t_h, t_x_count, t_y_count, scr_w = 800, scr_h = 600, isometric: false, limit_cam: true)
    @tile_size = Vector.new(t_w, t_h)
    @size = Vector.new(t_x_count, t_y_count)
    @cam = Rectangle.new(0, 0, scr_w, scr_h)
    @limit_cam = limit_cam
    @isometric = isometric
    if isometric
      initialize_isometric
    elsif limit_cam
      @max_x = t_x_count * t_w - scr_w
      @max_y = t_y_count * t_h - scr_h
    end
    set_camera(0, 0)
  end

  def absolute_size
    return Vector.new(@tile_size.x * @size.x, @tile_size.y * @size.y) unless @isometric

    avg = (@size.x + @size.y) * 0.5
    Vector.new (avg * @tile_size.x).to_i, (avg * @tile_size.y).to_i
  end

  def center
    absolute_size = self.absolute_size
    Vector.new(absolute_size.x * 0.5, absolute_size.y * 0.5)
  end

  def get_screen_pos(map_x, map_y)
    return Vector.new(map_x * @tile_size.x - @cam.x, map_y * @tile_size.y - @cam.y) unless @isometric

    Vector.new ((map_x - map_y - 1) * @tile_size.x * 0.5) - @cam.x + @x_offset,
               ((map_x + map_y) * @tile_size.y * 0.5) - @cam.y
  end

  def get_map_pos(scr_x, scr_y)
    return Vector.new((scr_x + @cam.x).idiv(@tile_size.x), (scr_y + @cam.y).idiv(@tile_size.y)) unless @isometric

    # Gets the position transformed to isometric coordinates
    v = get_isometric_position scr_x, scr_y

    # divides by the square size to find the position in the matrix
    Vector.new((v.x * @inverse_square_size).to_i, (v.y * @inverse_square_size).to_i)
  end

  def is_in_map(v)
    v.x >= 0 && v.y >= 0 && v.x < @size.x && v.y < @size.y
  end

  def set_camera(cam_x, cam_y)
    @cam.x = cam_x
    @cam.y = cam_y
    set_bounds
  end

  def move_camera(x, y)
    @cam.x += x
    @cam.y += y
    set_bounds
  end

  def foreach
    (@min_vis_y..@max_vis_y).each do |j|
      (@min_vis_x..@max_vis_x).each do |i|
        pos = get_screen_pos(i, j)
        yield i, j, pos.x, pos.y
      end
    end
  end

  private

  def set_bounds
    if @limit_cam
      if @isometric
        v1 = get_isometric_position(0, 0)
        v2 = get_isometric_position(@cam.w - 1, 0)
        v3 = get_isometric_position(@cam.w - 1, @cam.h - 1)
        v4 = get_isometric_position(0, @cam.h - 1)
        if v1.x < -@max_offset
          offset = -(v1.x + @max_offset)
          @cam.x += offset * SQRT_2_DIV_2
          @cam.y += offset * SQRT_2_DIV_2 / @tile_ratio
          v1.x = -@max_offset
        end
        if v2.y < -@max_offset
          offset = -(v2.y + @max_offset)
          @cam.x -= offset * SQRT_2_DIV_2
          @cam.y += offset * SQRT_2_DIV_2 / @tile_ratio
          v2.y = -@max_offset
        end
        if v3.x > @iso_abs_size.x + @max_offset
          offset = v3.x - @iso_abs_size.x - @max_offset
          @cam.x -= offset * SQRT_2_DIV_2
          @cam.y -= offset * SQRT_2_DIV_2 / @tile_ratio
          v3.x = @iso_abs_size.x + @max_offset
        end
        if v4.y > @iso_abs_size.y + @max_offset
          offset = v4.y - @iso_abs_size.y - @max_offset
          @cam.x += offset * SQRT_2_DIV_2
          @cam.y -= offset * SQRT_2_DIV_2 / @tile_ratio
          v4.y = @iso_abs_size.y + @max_offset
        end
      else
        @cam.x = @max_x if @cam.x > @max_x
        @cam.x = 0 if @cam.x < 0
        @cam.y = @max_y if @cam.y > @max_y
        @cam.y = 0 if @cam.y < 0
      end
    end

    @cam.x = @cam.x.round
    @cam.y = @cam.y.round
    if @isometric
      @min_vis_x = get_map_pos(0, 0).x
      @min_vis_y = get_map_pos(@cam.w - 1, 0).y
      @max_vis_x = get_map_pos(@cam.w - 1, @cam.h - 1).x
      @max_vis_y = get_map_pos(0, @cam.h - 1).y
    else
      @min_vis_x = @cam.x.idiv(@tile_size.x)
      @min_vis_y = @cam.y.idiv(@tile_size.y)
      @max_vis_x = (@cam.x + @cam.w - 1).idiv(@tile_size.x)
      @max_vis_y = (@cam.y + @cam.h - 1).idiv(@tile_size.y)
    end

    if @min_vis_y < 0
      @min_vis_y = 0
    elsif @min_vis_y > @size.y - 1
      @min_vis_y = @size.y - 1
    end

    if @max_vis_y < 0
      @max_vis_y = 0
    elsif @max_vis_y > @size.y - 1
      @max_vis_y = @size.y - 1
    end

    if @min_vis_x < 0
      @min_vis_x = 0
    elsif @min_vis_x > @size.x - 1
      @min_vis_x = @size.x - 1
    end

    if @max_vis_x < 0
      @max_vis_x = 0
    elsif @max_vis_x > @size.x - 1
      @max_vis_x = @size.x - 1
    end
  end

  def initialize_isometric
    @x_offset = (@size.y * 0.5 * @tile_size.x).round
    @tile_ratio = @tile_size.x.to_f / @tile_size.y
    square_size = @tile_size.x * SQRT_2_DIV_2
    @inverse_square_size = 1 / square_size
    @iso_abs_size = Vector.new(square_size * @size.x, square_size * @size.y)
    a = (@size.x + @size.y) * 0.5 * @tile_size.x
    @isometric_offset_x = (a - square_size * @size.x) * 0.5
    @isometric_offset_y = (a - square_size * @size.y) * 0.5
    return unless @limit_cam

    actual_cam_h = @cam.h * @tile_ratio
    @max_offset = actual_cam_h < @cam.w ? actual_cam_h : @cam.w
    @max_offset *= SQRT_2_DIV_2
  end

  def get_isometric_position(scr_x, scr_y)
    # Gets the position relative to the center of the map
    center = self.center
    position = Vector.new(scr_x + @cam.x - center.x, scr_y + @cam.y - center.y)

    # Multiplies by tile_ratio to get square tiles
    position.y *= @tile_ratio

    # Moves the center of the map accordingly
    center.y *= @tile_ratio

    # Rotates the position -45 degrees
    position.rotate! MINUS_PI_DIV_4

    # Returns the reference to the center of the map
    position += center

    # Returns to the corner of the screen
    position.x -= @isometric_offset_x
    position.y -= @isometric_offset_y
    position
  end
end
