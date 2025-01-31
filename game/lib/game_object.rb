class Sprite
  attr_accessor :x, :y, :img_index
  attr_reader :cols, :rows, :col_width, :row_height, :img_count

  def initialize(x, y, img_path, cols = 1, rows = 1, extension = 'png')
    @x = x
    @y = y
    @img_path = "sprites/#{img_path}.#{extension}"

    width, height = $gtk.calcspritebox(@img_path)
    @cols = cols
    @col_width = width.idiv(cols)
    @rows = rows
    @row_height = height.idiv(rows)
    @img_count = cols * rows
    @img_index = 0
    @index_index = 0
    @anim_counter = 0
    @animate_once_control = 0
  end

  def animate(indices, interval)
    @animate_once_control = 0 if @animate_once_control != 0

    @anim_counter += 1
    return unless @anim_counter >= interval

    @index_index += 1
    @index_index = 0 if @index_index >= indices.length
    @img_index = indices[@index_index]
    @anim_counter = 0
  end

  def animate_once(indices, interval)
    if @animate_once_control == 2
      return if indices == @animate_once_indices && interval == @animate_once_interval
      @animate_once_control = 0
    end

    unless @animate_once_control == 1
      @anim_counter = 0
      @img_index = indices[0]
      @index_index = 0
      @animate_once_indices = indices
      @animate_once_interval = interval
      @animate_once_control = 1
      return
    end

    @anim_counter += 1
    return unless @anim_counter >= interval

    if @index_index == indices.length - 1
      @animate_once_control = 2
      yield if block_given?
    else
      @index_index += 1
      @img_index = indices[@index_index]
      @anim_counter = 0
    end
  end

  def set_animation(index)
    @anim_counter = 0
    @img_index = index
    @index_index = 0
    @animate_once_control = 0
  end

  def draw(map: nil, scale_x: 1, scale_y: 1, alpha: 255, color: 0xffffff, angle: 0, z_index: 0, flip: nil, round: false)
    x = map ? @x - map.cam.x : @x
    y = map ? @y - map.cam.y : @y
    if round
      x = x.round
      y = y.round
    end
    height = scale_y * @row_height
    source_x = (@img_index % @cols) * @col_width
    source_y = (@rows - 1 - @img_index.idiv(@cols)) * @row_height
    r, g, b = hex_to_rgb(color)
    angle ||= 0

    Window.output(z_index) << {
      path: @img_path,
      x: x,
      y: Window.height - y - height,
      w: scale_x * @col_width,
      h: height,
      source_x: source_x,
      source_y: source_y,
      source_w: @col_width,
      source_h: @row_height,
      r: r,
      g: g,
      b: b,
      a: alpha,
      angle: -angle,
      flip_horizontally: flip == :horiz,
      flip_vertically: flip == :vert,
    }
  end
end

class GameObject < Sprite
  include Movement

  def initialize(x, y, w, h, img_path, cols = 1, rows = 1, extension: 'png', img_gap: Vector.new, mass: 1.0, max_speed: Vector.new(15, 15))
    super(x, y, img_path, cols, rows, extension)
    @w = w
    @h = h
    @img_gap = img_gap
    @mass = mass
    @max_speed = max_speed
    @speed = Vector.new
    @stored_forces = Vector.new
  end

  def draw(map: nil, scale_x: 1, scale_y: 1, alpha: 255, color: 0xffffff, angle: 0, z_index: 0, flip: nil, round: false, scale_image_gap: true)
    img_gap_scale_x = scale_image_gap ? scale_x : 1
    img_gap_scale_y = scale_image_gap ? scale_y : 1
    width = scale_x * @col_width
    height = scale_y * @row_height
    x = @x + (flip == :horiz ? -1 : 1) * @img_gap.x * img_gap_scale_x
    y = @y + (flip == :vert ? -1 : 1) * @img_gap.y * img_gap_scale_y
    x += @w - width if flip == :horiz
    y += @h - height if flip == :vert
    center_x = @x + @w * 0.5
    center_y = @y + @h * 0.5
    if round
      x = x.round
      y = y.round
      center_x = center_x.round
      center_y = center_y.round
    end
    offset_x = center_x - x
    offset_y = center_y - y
    source_x = (@img_index % @cols) * @col_width
    source_y = (@rows - 1 - @img_index.idiv(@cols)) * @row_height
    r, g, b = hex_to_rgb(color)
    angle ||= 0

    Window.output(z_index) << {
      path: @img_path,
      x: x - (map ? map.cam.x : 0),
      y: Window.height - (y - (map ? map.cam.y : 0)) - height,
      w: width,
      h: height,
      source_x: source_x,
      source_y: source_y,
      source_w: @col_width,
      source_h: @row_height,
      r: r,
      g: g,
      b: b,
      a: alpha,
      angle: -angle,
      angle_anchor_x: offset_x / width,
      angle_anchor_y: 1 - (offset_y / height),
      flip_horizontally: flip == :horiz,
      flip_vertically: flip == :vert,
    }
  end
end

class Effect < Sprite
  attr_reader :dead, :lifetime, :elapsed_time

  def initialize(x, y, img_path, cols, rows, interval: 10, indices: nil, lifetime: nil,
                 sound_path: nil, sound_extension: 'wav', sound_volume: 1.0)
    super(x, y, img_path, cols, rows)
    @elapsed_time = 0
    @indices = indices || (0...(@img_count)).to_a
    @interval = interval
    @lifetime = lifetime || @indices.length * interval

    Sound.new(sound_path, extension: sound_extension).play(sound_volume) if sound_path
  end

  def time_left
    @lifetime - @elapsed_time
  end

  # Updates the effect, animating and counting its remaining lifetime.
  def update
    return if @dead

    animate(@indices, @interval)
    @elapsed_time += 1
    @dead = true if @elapsed_time == @lifetime
  end

  def draw(map: nil, scale_x: 1, scale_y: 1, alpha: 255, color: 0xffffff, angle: 0, z_index: 0, flip: nil, round: false)
    super(map: map, scale_x: scale_x, scale_y: scale_y, alpha: alpha, color: color, angle: angle, z_index: z_index, flip: flip, round: round) unless @dead
  end
end
