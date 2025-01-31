module FormUtils
  def self.check_anchor(anchor, x, y, w, h, area_w = Window.width, area_h = Window.height)
    if anchor
      case anchor
      when :top, :top_center, :north then anchor_alias = :top_center; x += (area_w - w) / 2
      when :top_right, :northeast then anchor_alias = :top_right; x = area_w - w - x
      when :left, :center_left, :west then anchor_alias = :center_left; y += (area_h - h) / 2
      when :center then anchor_alias = :center; x += (area_w - w) / 2; y += (area_h - h) / 2
      when :right, :center_right, :east then anchor_alias = :center_right; x = area_w - w - x; y += (area_h - h) / 2
      when :bottom_left, :southwest then anchor_alias = :bottom_left; y = area_h - h - y
      when :bottom, :bottom_center, :south then anchor_alias = :bottom_center; x += (area_w - w) / 2; y = area_h - h - y
      when :bottom_right, :southeast then anchor_alias = :bottom_right; x = area_w - w - x; y = area_h - h - y
      else anchor_alias = :top_left
      end
    else
      anchor_alias = :top_left
    end
    [anchor_alias, x, y]
  end
end

class Panel
  attr_reader :x, :y, :w, :h, :enabled, :components
  attr_accessor :visible

  def initialize(x, y, w, h, components: [], img_path: nil, img_mode: :normal, img_extension: 'png', scale_x: 1, scale_y: 1, anchor: nil)
    _, x, y = FormUtils.check_anchor(anchor, x, y, w, h)
    @x = x; @y = y; @w = w; @h = h
    @components = components
    components.each do |c|
      _, x, y = FormUtils.check_anchor(c.anchor, c.anchor_offset_x, c.anchor_offset_y, c.w, c.h, @w, @h)
      c.set_position(@x + x, @y + y)
      c.panel = self
    end

    @scale_x = scale_x
    @scale_y = scale_y
    if img_path
      @img_path = "sprites/#{img_path}.#{img_extension}"
      @img_mode = img_mode
      width, height = $gtk.calcspritebox(@img_path)
      if img_mode == :tiled
        @col_width = width / 3
        @row_height = height / 3
        @tile_w = @col_width * @scale_x
        @tile_h = @row_height * @scale_y
        @center_w = @w - 2 * @tile_w
        @center_h = @h - 2 * @tile_h
      end
    end

    @visible = @enabled = true
  end

  def update
    return unless visible
    components.each(&:update)
  end

  def enabled=(value)
    @enabled = value
    components.each { |c| c.enabled = value }
  end

  def add_component(c)
    _, x, y = FormUtils.check_anchor(c.anchor, c.anchor_offset_x, c.anchor_offset_y, c.w, c.h, @w, @h)
    c.set_position(@x + x, @y + y)
    components << c
  end

  def draw(color: 0xffffff, alpha: 255, z_index: 0)
    return unless visible

    if @img_path
      r, g, b = hex_to_rgb(color)
      if @img_mode == :tiled
        draw_tile(x, y, @tile_w, @tile_h, 0, 2 * @row_height, r, g, b, alpha, z_index)
        draw_tile(x + @tile_w, y, @center_w, @tile_h, @col_width, 2 * @row_height, r, g, b, alpha, z_index) if @center_w > 0
        draw_tile(x + w - @tile_w, y, @tile_w, @tile_h, 2 * @col_width, 2 * @row_height, r, g, b, alpha, z_index)
        draw_tile(x, y + @tile_h, @tile_w, @center_h, 0, @row_height, r, g, b, alpha, z_index) if @center_h > 0
        draw_tile(x + @tile_w, y + @tile_h, @center_w, @center_h, @col_width, @row_height, r, g, b, alpha, z_index) if @center_w > 0 && @center_h > 0
        draw_tile(x + w - @tile_w, y + @tile_h, @tile_w, @center_h, 2 * @col_width, @row_height, r, g, b, alpha, z_index) if @center_h > 0
        draw_tile(x, y + h - @tile_h, @tile_w, @tile_h, 0, 0, r, g, b, alpha, z_index)
        draw_tile(x + @tile_w, y + h - @tile_h, @center_w, @tile_h, @col_width, 0, r, g, b, alpha, z_index) if @center_w > 0
        draw_tile(x + w - @tile_w, y + h - @tile_h, @tile_w, @tile_h, 2 * @col_width, 0, r, g, b, alpha, z_index)
      else
        Window.output(z_index) << { path: @img_path, x: x, y: Window.height - y - h, w: w, h: h, r: r, g: g, b: b, a: alpha }
      end
    end

    components.each { |c| c.draw(color: color, alpha: alpha, z_index: z_index) if c.visible }
  end

  private

  def draw_tile(x, y, w, h, source_x, source_y, r, g, b, a, z_index)
    Window.output(z_index) << {
      path: @img_path,
      x: x,
      y: Window.height - y - h,
      w: w,
      h: h,
      source_x: source_x,
      source_y: source_y,
      source_w: @col_width,
      source_h: @row_height,
      r: r,
      g: g,
      b: b,
      a: a
    }
  end
end

class Component
  attr_reader :x, :y, :w, :h, :anchor, :anchor_offset_x, :anchor_offset_y, :text
  attr_accessor :enabled, :visible, :params, :panel

  def initialize(x, y, w, h, anchor, font, text, text_color, disabled_text_color)
    @anchor, @x, @y = FormUtils.check_anchor(anchor, x, y, w, h)
    @anchor_offset_x = x
    @anchor_offset_y = y
    @w = w
    @h = h
    @font = font
    @text = text
    @text_color = text_color
    @disabled_text_color = disabled_text_color
    @enabled = @visible = true
  end

  def set_position(x, y)
    @x = x
    @y = y
  end

  def update; end
end

class Button < Component
  attr_reader :state

  def initialize(x, y, anchor: :top_left, font: nil, text: nil, text_color: 0, disabled_text_color: 0x333333, **options, &action)
    @scale = options[:scale] || 1
    img_path = options[:img_path]
    if img_path
      @img_path = "sprites/#{img_path}.#{options[:img_extension] || 'png'}"
      width, height = $gtk.calcspritebox(@img_path)
      @cols ||= 1
      @col_width = width.idiv(@cols)
      @rows = 4
      @row_height = height.idiv(@rows)
      w = @scale * @col_width
      h = @scale * @row_height
    else
      w = options[:w] || 100
      h = options[:h] || 30
    end

    super(x, y, w, h, anchor, font, text, text_color, disabled_text_color)

    @over_text_color = options[:over_text_color] || 0
    @down_text_color = options[:down_text_color] || 0
    @center_x = options.fetch(:center_x, true)
    @center_y = options.fetch(:center_y, true)
    @margin_x = options[:margin_x] || 0
    @margin_y = options[:margin_y] || 0
    @params = options[:params]
    @action = action

    @state = :up
    @img_index = 0

    set_position(@x, @y)
  end

  def enabled=(value)
    @enabled = value
    @state = :up
    @img_index = value ? 0 : 3
  end

  def text=(value)
    @text = value
    set_text_position
  end

  def set_position(x, y)
    @x = x
    @y = y
    set_text_position
  end

  def click
    @action&.call(params)
  end

  def update
    return unless enabled && visible

    mouse_over = Mouse.over?(x, y, w, h)
    mouse_press = Mouse.button_pressed?(:left) && !Mouse.click_captured?
    mouse_rel = Mouse.button_released?(:left)

    if @state == :up
      if mouse_over
        @img_index = 1
        @state = :over
      else
        @img_index = 0
      end
    elsif @state == :over
      if !mouse_over
        @img_index = 0
        @state = :up
      elsif mouse_press
        @img_index = 2
        @state = :down
        Mouse.click_captured = true
      else
        @img_index = 1
      end
    elsif @state == :down
      if !mouse_over
        @img_index = 0
        @state = :down_out
      elsif mouse_rel
        @img_index = 1
        @state = :over
        click
      else
        @img_index = 2
      end
    else # :down_out
      if mouse_over
        @img_index = 2
        @state = :down
      elsif mouse_rel
        @img_index = 0
        @state = :up
      else
        @img_index = 0
      end
    end
  end

  def draw(color: 0xffffff, alpha: 255, z_index: 0)
    return unless visible

    if @img_path
      r, g, b = hex_to_rgb(color)
      Window.output(z_index) << {
        path: @img_path,
        x: x,
        y: Window.height - y - h,
        w: w,
        h: h,
        source_x: (@img_index % @cols) * @col_width,
        source_y: (@rows - 1 - @img_index.idiv(@cols)) * @row_height,
        source_w: @col_width,
        source_h: @row_height,
        r: r,
        g: g,
        b: b,
        a: alpha
      }
    else
      rect_color =
        if @enabled
          case @state
          when :over then 0xdddddd
          when :down then 0xbbbbbb
          else            0xffffff
          end
        else
          0x999999
        end
      Window.draw_rect(x, y, w, h, (alpha << 24) | rect_color, z_index)
    end

    return unless @font && @text

    rel_x = @center_x ? 0.5 : 0
    rel_y = @center_y ? 0.5 : 0
    text_color = if @enabled
                   case @state
                   when :over then @over_text_color
                   when :down then @down_text_color
                   else            @text_color
                   end
                 else
                   @disabled_text_color
                 end
    text_color |= (alpha << 24)
    @font.draw_text_rel(@text, @text_x, @text_y, rel_x, rel_y, text_color, scale: @scale, z_index: z_index)
  end

  private

  def set_text_position
    @text_x = @center_x ? x + @w / 2 : x
    @text_y = @center_y ? y + @h / 2 : y
    @text_x += @margin_x
    @text_y += @margin_y
  end
end

class ToggleButton < Button
  attr_reader :checked

  def initialize(x, y, anchor: :top_left, font: nil, text: nil, text_color: 0, disabled_text_color: 0x333333, **options, &action)
    @cols = 2
    super(x, y, anchor: anchor, font: font, text: text, text_color: text_color, disabled_text_color: disabled_text_color, **options, &action)

    @checked = options[:checked] || false
  end

  def enabled=(value)
    @enabled = value
    @state = :up
    @img_index = value ? 0 : 6
    @img_index += 1 if @checked
  end

  def checked=(value)
    @action&.call(value, @params) if value != @checked
    @checked = value
  end

  def click
    @checked = !@checked
    @action&.call(@checked, @params)
  end

  def update
    return unless enabled && visible

    super
    @img_index *= 2
    @img_index += 1 if @checked
  end
end

class TextField < Component
  KEYS = (
    %i[a b c d e f g h i j k l m n o p q r s t u v w x y z one two three four five six seven eight nine zero space] +
    %i[hyphen equal single_quotation_mark back_slash forward_slash comma period semicolon open_square_brace close_square_brace]
  ).freeze
  CHARS = (
    %w[a b c d e f g h i j k l m n o p q r s t u v w x y z 1 2 3 4 5 6 7 8 9 0] + [' '] +
    %w{- = ' \\ / , . ; [ ]}
  ).freeze
  SHIFT_CHARS = (
    %w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ! @ # $ % ^ & * ( )] + [' '] +
    %w[_ + " | ? < > : { }]
  ).freeze

  attr_reader :focused

  def initialize(x, y, anchor: :top_left, font:, text: nil, text_color: 0, disabled_text_color: 0x333333, **options, &on_text_changed)
    @scale = options[:scale] || 1
    img_path = options[:img_path]
    if img_path
      @img_path = "sprites/#{img_path}.#{options[:img_extension] || 'png'}"
      @col_width, height = $gtk.calcspritebox(@img_path)
      @row_height = height.idiv(2)
      w = @scale * @col_width
      h = @scale * @row_height
    else
      w = options[:w] || 150
      h = options[:h] || 30
    end

    super(x, y, w, h, anchor, font, text, text_color, disabled_text_color)

    @cursor_img_path = options[:cursor_img_path] && "sprites/#{options[:cursor_img_path]}.#{options[:cursor_img_extension] || 'png'}"
    if @cursor_img_path
      cursor_img_width, cursor_img_height = $gtk.calcspritebox(@cursor_img_path)
      @cursor_w = @scale * cursor_img_width
      @cursor_h = @scale * cursor_img_height
      @cursor_img_gap = options[:cursor_img_gap] || Vector.new
    end
    @max_length = options[:max_length] || 100
    @focused = options.fetch(:focused, true)
    @margin_x = options[:margin_x] || 0
    @margin_y = options[:margin_y] || 0
    @center_y = options.fetch(:center_y, true)
    @text_x = @x + @margin_x
    @text_y = @y + @margin_y + (@center_y ? (@h - @font.height * @scale) / 2 : 0)
    @selection_color = options[:selection_color] || 0x66000000
    @cursor_blink_interval = options[:cursor_blink_interval] || 30
    @allowed_chars = options[:allowed_chars]
    @params = options[:params]

    @nodes = [@text_x]
    @cur_node = 0
    @cursor_visible = false
    @cursor_timer = 0
    @on_text_changed = on_text_changed

    send(:text=, text || '', false)
  end

  def update
    return unless enabled && visible

    ################################ Mouse ################################
    if Mouse.over?(@x, @y, @w, @h)
      if !@focused && Mouse.button_pressed?(:left) && !Mouse.click_captured?
        focus
        return
      end
    elsif Mouse.button_pressed?(:left)
      unfocus
    end

    return unless @focused

    unless Mouse.click_captured?
      if Mouse.double_click?(:left)
        if @nodes.size > 1
          @anchor1 = 0
          @anchor2 = @nodes.size - 1
          @cur_node = @anchor2
          @double_clicked = true
        end
        set_cursor_visible
        Mouse.click_captured = true
      elsif Mouse.button_pressed?(:left)
        focus_and_set_anchor
        Mouse.click_captured = true
      elsif Mouse.button_down?(:left)
        if @anchor1 && !@double_clicked
          set_node_by_mouse
          @anchor2 = @cur_node == @anchor1 ? nil : @cur_node
          set_cursor_visible
        end
        Mouse.click_captured = true
      elsif Mouse.button_released?(:left) && @anchor1 && !@double_clicked
        if @cur_node == @anchor1
          @anchor1 = nil
        else
          @anchor2 = @cur_node
        end
      end
    end

    @cursor_timer += 1
    if @cursor_timer >= @cursor_blink_interval
      @cursor_visible = !@cursor_visible
      @cursor_timer = 0
    end

    ############################### Keyboard ##############################
    shift = KB.key_down?(:shift)
    if KB.key_pressed?(:shift)
      @anchor1 = @cur_node if @anchor1.nil?
    elsif KB.key_released?(:shift)
      @anchor1 = nil if @anchor2.nil?
    end

    inserted = false
    KEYS.each_with_index do |key, i|
      next unless KB.key_pressed?(key) || KB.key_held?(key)

      remove_interval(true) if @anchor1 && @anchor2
      insert_char(shift ? SHIFT_CHARS[i] : CHARS[i])
      inserted = true
      break
    end
    return if inserted

    if KB.key_pressed?(:backspace) || KB.key_held?(:backspace)
      if @anchor1 && @anchor2
        remove_interval
      elsif @cur_node > 0
        remove_char(true)
      end
    elsif KB.key_pressed?(:delete) || KB.key_held?(:delete)
      if @anchor1 && @anchor2
        remove_interval
      elsif @cur_node < @nodes.size - 1
        remove_char(false)
      end
    elsif KB.key_pressed?(:left_arrow) || KB.key_held?(:left_arrow)
      if @anchor1
        if shift
          if @cur_node > 0
            @cur_node -= 1
            @anchor2 = @cur_node
            set_cursor_visible
          end
        elsif @anchor2
          @cur_node = @anchor1 < @anchor2 ? @anchor1 : @anchor2
          @anchor1 = nil
          @anchor2 = nil
          set_cursor_visible
        end
      elsif @cur_node > 0
        @cur_node -= 1
        set_cursor_visible
      end
    elsif KB.key_pressed?(:right_arrow) || KB.key_held?(:right_arrow)
      if @anchor1
        if shift
          if @cur_node < @nodes.size - 1
            @cur_node += 1
            @anchor2 = @cur_node
            set_cursor_visible
          end
        elsif @anchor2
          @cur_node = @anchor1 > @anchor2 ? @anchor1 : @anchor2
          @anchor1 = nil
          @anchor2 = nil
          set_cursor_visible
        end
      elsif @cur_node < @nodes.size - 1
        @cur_node += 1
        set_cursor_visible
      end
    elsif KB.key_pressed?(:home)
      @cur_node = 0
      if shift
        @anchor2 = @cur_node
      else
        @anchor1 = @anchor2 = nil
      end
      set_cursor_visible
    elsif KB.key_pressed?(:end)
      @cur_node = @nodes.size - 1
      if shift
        @anchor2 = @cur_node
      else
        @anchor1 = @anchor2 = nil
      end
      set_cursor_visible
    end
  end

  def text=(value, trigger_changed = true)
    @text = ''
    @nodes = [@text_x]
    x = @nodes[0]
    char_count = 0
    value.each_true_char do |char|
      @text += char
      x += @font.text_width(char) * @scale
      @nodes << x

      char_count += 1
      break if char_count >= @max_length
    end

    @cur_node = @nodes.size - 1
    @anchor1 = @anchor2 = nil
    @on_text_changed&.call(@text, @params) if trigger_changed
  end

  def selected_text
    return '' if @anchor2.nil?
    min = @anchor1 < @anchor2 ? @anchor1 : @anchor2
    max = min == @anchor1 ? @anchor2 : @anchor1

    text = ''
    @text.each_true_char do |char, index|
      next if index < min
      break if index >= max

      text += char
    end
    text
  end

  def focus
    @focused = true
    @anchor2 = nil
    @double_clicked = false
    set_node_by_mouse
    set_cursor_visible
  end

  def unfocus
    @anchor1 = @anchor2 = nil
    @cursor_visible = @focused = false
    @cursor_timer = 0
  end

  def set_position(x, y)
    d_x = x - @x
    d_y = y - @y
    @x = x
    @y = y
    @text_x += d_x
    @text_y += d_y
    @nodes.map! { |n| n + d_x }
  end

  def draw(color: 0xffffff, alpha: 255, z_index: 0)
    return unless visible

    r, g, b = hex_to_rgb(color)
    if @img_path
      Window.output(z_index) << {
        path: @img_path,
        x: x,
        y: Window.height - y - h,
        w: w,
        h: h,
        source_x: 0,
        source_y: enabled ? @row_height : 0,
        source_w: @col_width,
        source_h: @row_height,
        r: r,
        g: g,
        b: b,
        a: alpha
      }
    else
      rect_color = enabled ? 0xffffff : 0x999999
      Window.draw_rect(x, y, w, h, (alpha << 24) | rect_color, z_index)
    end

    text_color = enabled ? @text_color : @disabled_text_color
    @font.draw_text(@text, @text_x, @text_y, (alpha << 24) | text_color, scale: @scale, z_index: z_index) unless @text.empty?

    if @anchor1 && @anchor2
      min = @anchor1 < @anchor2 ? @anchor1 : @anchor2
      max = min == @anchor1 ? @anchor2 : @anchor1
      Window.draw_rect(@nodes[min], @text_y, @nodes[max] - @nodes[min], @font.height * @scale, @selection_color, z_index)
    end

    if @cursor_visible
      cursor_x = @nodes[@cur_node]
      if @cursor_img_path
        Window.output(z_index) << {
          path: @cursor_img_path,
          x: cursor_x + @cursor_img_gap.x,
          y: Window.height - @text_y - @cursor_h - @cursor_img_gap.y,
          w: @cursor_w,
          h: @cursor_h,
          r: r,
          g: g,
          b: b,
          a: alpha
        }
      else
        Window.draw_rect(cursor_x, @text_y, 1, @font.height * @scale, 0xff000000, z_index)
      end
    end
  end

  def enabled=(value)
    @enabled = value
    unfocus unless @enabled
  end

  def visible=(value)
    @visible = value
    unfocus unless @visible
  end

  private

  def focus_and_set_anchor
    focus
    @anchor1 = @cur_node
  end

  def set_cursor_visible
    @cursor_visible = true
    @cursor_timer = 0
  end

  def set_node_by_mouse
    index = @nodes.size - 1
    @nodes.each_with_index do |n, i|
      if n >= Mouse.x
        index = i
        break
      end
    end
    if index > 0
      d1 = @nodes[index] - Mouse.x
      d2 = Mouse.x - @nodes[index - 1]
      index -= 1 if d1 > d2
    end
    @cur_node = index
  end

  def insert_char(char)
    return unless @text.true_size < @max_length && (@allowed_chars.nil? || @allowed_chars.include?(char))

    @text.true_insert(@cur_node, char)
    @nodes.insert(@cur_node + 1, @nodes[@cur_node] + @font.text_width(char) * @scale)
    ((@cur_node + 2)...@nodes.size).each do |i|
      @nodes[i] += @font.text_width(char) * @scale
    end
    @cur_node += 1
    set_cursor_visible
    @on_text_changed&.call(@text, @params)
  end

  def remove_interval(will_insert = false)
    min = @anchor1 < @anchor2 ? @anchor1 : @anchor2
    max = min == @anchor1 ? @anchor2 : @anchor1
    interval_width = 0
    (min...max).each do |i|
      interval_width += @font.text_width(@text.true_char_at(i)) * @scale
      @nodes.delete_at(min + 1)
    end
    @text = @text.delete_true_slice(min, max)
    ((min + 1)...@nodes.size).each do |i|
      @nodes[i] -= interval_width
    end
    @cur_node = min
    @anchor1 = @anchor2 = nil
    set_cursor_visible
    @on_text_changed&.call(@text, @params) unless will_insert
  end

  def remove_char(back)
    @cur_node -= 1 if back
    char_width = @font.text_width(@text.true_char_at(@cur_node)) * @scale
    @text = @text.delete_true_slice(@cur_node, @cur_node + 1)
    @nodes.delete_at(@cur_node + 1)
    ((@cur_node + 1)...@nodes.size).each do |i|
      @nodes[i] -= char_width
    end
    set_cursor_visible
    @on_text_changed&.call(@text, @params)
  end
end

class DropDownList < Component
  attr_reader :values, :value, :open

  def initialize(x, y, anchor: :top_left, font: nil, text_color: 0, disabled_text_color: 0x333333, **options, &on_changed)
    @values = options[:values] || []
    raise 'Must provide at least one value' if @values.empty?

    @value = @values[options[:selected_index] || 0]
    @buttons = [
      Button.new(x, y, anchor: anchor, font: font, text: @value, text_color: text_color, disabled_text_color: disabled_text_color, **options) do
        toggle
      end
    ]

    super(x, y, @buttons[0].w, @buttons[0].h, anchor, font, @value, text_color, disabled_text_color)

    options.merge!(img_path: options[:opt_img_path])
    @values.each do |v|
      b = Button.new(0, 0, font: font, text: v, text_color: text_color, disabled_text_color: disabled_text_color, **options) do
        self.value = v
        toggle
      end
      b.visible = false
      @buttons << b
    end
    @buttons[1..-1].each_with_index do |b, i|
      b.set_position(@x, @y + @h + i * @buttons[1].h)
    end

    @max_h = @h + @values.size * @buttons[1].h
    @on_changed = on_changed
  end

  def update
    return unless enabled && visible

    if @open && Mouse.button_pressed?(:left) && !Mouse.over?(@x, @y, @w, @max_h)
      toggle
      return
    end
    @buttons.each(&:update)
  end

  def value=(val)
    return unless @values.include?(val)

    old = @value
    @value = @buttons[0].text = val
    @on_changed&.call(old, val)
  end

  def enabled=(value)
    toggle if @open
    @buttons[0].enabled = value
    @enabled = value
  end

  def set_position(x, y)
    @x = x
    @y = y
    @buttons[0].set_position(x, y)
    @buttons[1..-1].each_with_index { |b, i| b.set_position(x, y + h + i * @buttons[1].h) }
  end

  def draw(color: 0xffffff, alpha: 255, z_index: 0)
    return unless visible

    @buttons.each { |b| b.draw(color: color, alpha: alpha, z_index: z_index) }
  end

  private

  def toggle
    if @open
      @buttons[1..-1].each { |b| b.visible = false }
      @open = false
    else
      @buttons[1..-1].each { |b| b.visible = true }
      @open = true
    end
  end
end

class Label < Component
  def initialize(x, y, font, text, anchor: :top_left, color: 0, disabled_color: 0x333333, scale: 1)
    @scale = scale
    w = font.text_width(text) * scale
    h = font.height * scale
    super(x, y, w, h, anchor, font, text, color, disabled_color)
  end

  def text=(new_text)
    @text = new_text
    @w = @font.text_width(@text) * @scale
    _, x, y = FormUtils.check_anchor(@anchor, @anchor_offset_x, @anchor_offset_y, @w, @h, panel ? panel.w : Window.width, panel ? panel.h : Window.height)
    if panel
      set_position(panel.x + x, panel.y + y)
    else
      set_position(x, y)
    end
  end

  def draw(color: 0xffffff, alpha: 255, z_index: 0)
    r1, g1, b1 = hex_to_rgb(enabled ? @text_color : @disabled_text_color)
    r2, g2, b2 = hex_to_rgb(color)
    r = (r1 * r2 / 255).round
    g = (g1 * g2 / 255).round
    b = (b1 * b2 / 255).round
    c = (alpha << 24) | (r << 16) | (g << 8) | b
    @font.draw_text(@text, @x, @y, c, scale: @scale, z_index: z_index)
  end
end
