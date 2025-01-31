WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
WINDOW_RATIO = WINDOW_WIDTH / WINDOW_HEIGHT

def hex_to_rgb(color)
  [color >> 16, (color >> 8) & 0xff, color & 0xff]
end

def hex_to_argb(color)
  [color >> 24, (color >> 16) & 0xff, (color >> 8) & 0xff, color & 0xff]
end

class Vector
  attr_accessor :x, :y

  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  def ==(other, precision = 6)
    @x.round(precision) == other.x.round(precision) &&
      @y.round(precision) == other.y.round(precision)
  end

  def !=(other, precision = 6)
    @x.round(precision) != other.x.round(precision) ||
      @y.round(precision) != other.y.round(precision)
  end

  def +(other)
    Vector.new(@x + other.x, @y + other.y)
  end

  def -(other)
    Vector.new(@x - other.x, @y - other.y)
  end

  def *(scalar)
    Vector.new(@x * scalar, @y * scalar)
  end

  def /(scalar)
    Vector.new(@x / scalar, @y / scalar)
  end

  def distance(other)
    dx = @x - other.x
    dy = @y - other.y
    Math.sqrt(dx**2 + dy**2)
  end

  def rotate(radians)
    sin = Math.sin(radians)
    cos = Math.cos(radians)
    Vector.new(cos * @x - sin * @y, sin * @x + cos * @y)
  end

  def rotate!(radians)
    sin = Math.sin(radians)
    cos = Math.cos(radians)
    prev_x = @x
    @x = cos * @x - sin * @y
    @y = sin * prev_x + cos * @y
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end

class Rectangle
  attr_accessor :x, :y, :w, :h

  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def intersect?(r)
    @x < r.x + r.w && @x + @w > r.x && @y < r.y + r.h && @y + @h > r.y
  end
end

class G
  class << self
    attr_accessor :gravity, :min_speed, :ramp_contact_threshold,
                  :ramp_slip_threshold, :ramp_slip_force, :kb_held_delay,
                  :kb_held_interval, :double_click_delay

    def initialize(screen_width: 1280, screen_height: 720, fullscreen: true,
                   gravity: Vector.new(0, 1), min_speed: Vector.new(0.01, 0.01),
                   ramp_contact_threshold: 4, ramp_slip_threshold: 1, ramp_slip_force: 1,
                   kb_held_delay: 30, kb_held_interval: 3, double_click_delay: 8)
      @gravity = gravity
      @min_speed = min_speed
      @ramp_contact_threshold = ramp_contact_threshold
      @ramp_slip_threshold = ramp_slip_threshold
      @ramp_slip_force = ramp_slip_force
      @kb_held_delay = kb_held_delay
      @kb_held_interval = kb_held_interval
      @double_click_delay = double_click_delay

      Window.set_screen_size(screen_width, screen_height)
      Window.toggle_fullscreen if fullscreen
      Mouse.initialize
      KB.initialize
    end
  end
end

class Window
  RENDER_TARGET_ID = :__minidragon_screen

  class << self
    attr_reader :width, :height, :true_width, :true_height, :offset_x, :offset_y

    def set_screen_size(width, height)
      @width = width
      @height = height
      @layers = {}

      if width == WINDOW_WIDTH && height == WINDOW_HEIGHT
        @zoom_factor = 1.0
        @true_width = width
        @true_height = height
        @offset_x = @offset_y = 0
        @use_render_target = false
        return
      end

      @use_render_target = true
      if width / height >= WINDOW_RATIO
        @zoom_factor = WINDOW_WIDTH / width
        @true_width = WINDOW_WIDTH
        @true_height = height * @zoom_factor
        @offset_x = 0
        @offset_y = ((WINDOW_HEIGHT - @true_height) / 2).round
      else
        @zoom_factor = WINDOW_HEIGHT / height
        @true_width = width * @zoom_factor
        @true_height = WINDOW_HEIGHT
        @offset_x = ((WINDOW_WIDTH - @true_width) / 2).round
        @offset_y = 0
      end
    end

    def toggle_fullscreen
      $args.gtk.set_window_fullscreen(!$args.gtk.window_fullscreen?)
    end

    def close
      $args.gtk.request_quit
    end

    def begin_draw(color = nil)
      @layers.clear
      clear(color) if color
    end

    def output(z_index = 0)
      @layers[z_index] ||= []
    end

    def end_draw
      output = use_render_target ? $args.outputs[RENDER_TARGET_ID] : $args.outputs
      if use_render_target
        output.transient!
        $args.outputs.solids << [0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 0, 0, 0]
      end

      @layers.keys.sort.each do |key|
        output.primitives << @layers[key]
      end
      return unless use_render_target

      $args.outputs.sprites << {
        path: RENDER_TARGET_ID,
        x: @offset_x,
        y: WINDOW_HEIGHT - @offset_y - @true_height,
        w: @true_width,
        h: @true_height,
        source_w: width,
        source_h: height
      }
    end

    def clear(color)
      draw_rect(0, 0, width, height, (255 << 24) | color)
    end

    def draw_rect(x, y, w, h, color, z_index = 0)
      a, r, g, b = hex_to_argb(color)
      output(z_index) << {
        path: :pixel,
        x: x,
        y: Window.height - y - h,
        w: w,
        h: h,
        r: r,
        g: g,
        b: b,
        a: a
      }
    end

    private

    attr_reader :use_render_target
  end
end

class Mouse
  class << self
    attr_reader :x, :y
    attr_writer :click_captured

    def initialize
      @down = {}
      @prev_down = {}
      @dbl_click = {}
      @dbl_click_timer = {}
    end

    def update
      @click_captured = false
      @prev_down = @down.clone
      @down.clear
      @dbl_click.clear

      @dbl_click_timer.each do |k, v|
        if v < G.double_click_delay
          @dbl_click_timer[k] += 1
        else
          @dbl_click_timer.delete(k)
        end
      end

      %i[left middle right].each do |key|
        if $args.inputs.mouse.send("button_#{key}")
          @down[key] = true
          @dbl_click[key] = true if @dbl_click_timer[key]
          @dbl_click_timer.delete(key)
        elsif @prev_down[key]
          @dbl_click_timer[key] = 0
        end
      end

      @x = ($args.inputs.mouse.x - Window.offset_x) / Window.true_width * Window.width
      @y = (1 - ($args.inputs.mouse.y - Window.offset_y) / Window.true_height) * Window.height
    end

    def button_pressed?(btn)
      @down[btn] && @prev_down[btn].nil?
    end

    def button_down?(btn)
      !@down[btn].nil?
    end

    def button_released?(btn)
      @prev_down[btn] && @down[btn].nil?
    end

    def double_click?(btn)
      @dbl_click[btn]
    end

    def over?(x, y = nil, w = nil, h = nil)
      return @x >= x.x && @x < x.x + x.w && @y >= x.y && @y < x.y + x.h if x.is_a?(Rectangle)
      @x >= x && @x < x + w && @y >= y && @y < y + h
    end

    def click_captured?
      @click_captured
    end
  end
end

class KB
  class << self
    FUNCTION_KEYS = {
      1073741882 => :f1,
      1073741883 => :f2,
      1073741884 => :f3,
      1073741885 => :f4,
      1073741886 => :f5,
      1073741887 => :f6,
      1073741888 => :f7,
      1073741889 => :f8,
      1073741890 => :f9,
      1073741891 => :f10,
      1073741892 => :f11,
      1073741893 => :f12
    }.freeze

    GAMEPAD_KEYS = %i[up down left right a b x y l1 r1 l2 r2 start select].freeze

    def initialize
      @down = []
      @prev_down = []
      @held_timer = {}
      @held_interval = {}
    end

    def update
      @held_timer.each do |k, v|
        if v < G.kb_held_delay
          @held_timer[k] += 1
        else
          @held_interval[k] = 0
          @held_timer.delete k
        end
      end

      @held_interval.each do |k, v|
        if v < G.kb_held_interval
          @held_interval[k] += 1
        else
          @held_interval[k] = 0
        end
      end

      @prev_down = @down.clone
      @down.clear

      $args.inputs.keyboard.keys[:down_or_held].each do |k|
        @down << k
        @held_timer[k] = 0 unless @prev_down.include?(k)
      end
      down_keycodes = $args.inputs.keyboard.key_down.keycodes.keys
      held_keycodes = $args.inputs.keyboard.key_held.keycodes.keys
      FUNCTION_KEYS.each do |keycode, k|
        next unless down_keycodes.include?(keycode) || held_keycodes.include?(keycode)

        @down << k
        @held_timer[k] = 0 unless @prev_down.include?(k)
      end
      GAMEPAD_KEYS.each do |key|
        $args.inputs.controllers.each_with_index do |controller, index|
          next unless controller.send(key)

          k = "gp_#{index}_#{key}".to_sym
          @down << k
          @held_timer[k] = 0 unless @prev_down.include?(k)
        end
      end

      @prev_down.each do |k|
        next if @down.include?(k)

        @held_timer.delete(k)
        @held_interval.delete(k)
      end
    end

    def key_pressed?(key)
      key_down?(key) && !@prev_down.include?(key)
    end

    def key_down?(key)
      @down.include?(key)
    end

    def key_released?(key)
      @prev_down.include?(key) && !key_down?(key)
    end

    def key_held?(key)
      @held_interval[key] == G.kb_held_interval
    end
  end
end
