class String
  def each_true_char
    index = 0
    char_bytes = []
    each_byte do |byte|
      char_bytes << byte
      next unless valid_utf8_char?(char_bytes)

      char = char_bytes.pack('C*')
      char_bytes.clear

      yield char, index
      index += 1
    end
  end

  def true_size
    count = 0
    each_true_char { count += 1 }
    count
  end

  def true_insert(index, other_str)
    char_bytes = []
    idx = 0
    each_byte.with_index do |byte, byte_index|
      return insert(byte_index, other_str) if idx == index

      char_bytes << byte
      next unless valid_utf8_char?(char_bytes)

      char_bytes.clear
      idx += 1
    end

    insert(size, other_str)
  end

  def delete_true_slice(start_at, end_at)
    result = ''
    each_true_char do |char, index|
      next if index >= start_at && index < end_at

      result += char
    end
    result
  end

  def true_char_at(index)
    idx = 0
    each_true_char do |char|
      return char if idx == index
      idx += 1
    end
    nil
  end

  alias :true_count :true_size
  alias :true_length :true_size

  private

  def valid_utf8_char?(bytes)
    return true if (bytes[0] & 0b10000000) == 0
    return true if (bytes[0] >> 5) == 0b110 && bytes.size == 2
    return true if (bytes[0] >> 4) == 0b1110 && bytes.size == 3
    return true if (bytes[0] >> 3) == 0b11110 && bytes.size == 4
    false
  end
end

class Font
  attr_reader :height

  def initialize(path, height, extension: 'ttf')
    @path = "fonts/#{path}.#{extension}"
    @height = height
  end

  def draw_text(text, x, y, color, scale: 1, z_index: 0)
    draw_text_rel(text, x, y, 0, 0, color, scale: scale, z_index: z_index)
  end

  def draw_text_rel(text, x, y, rel_x, rel_y, color, scale: 1, z_index: 0)
    horiz_alignment = rel_to_alignment_enum(rel_x)
    vert_aligment = rel_to_alignment_enum(rel_y, true)
    a, r, g, b = hex_to_argb(color)
    Window.output(z_index) << {
      text: text.to_s,
      x: x,
      y: Window.height - y,
      size_enum: height_to_size_enum(scale * height),
      alignment_enum: horiz_alignment,
      vertical_alignment_enum: vert_aligment,
      r: r,
      g: g,
      b: b,
      a: a,
      font: @path
    }
  end

  def text_width(text)
    $gtk.calcstringbox(text, height_to_size_enum(height), @path)[0]
  end

  private

  def height_to_size_enum(h)
    h.idiv(2) - 11
  end

  def rel_to_alignment_enum(rel, vert = false)
    case rel
    when 0   then vert ? 2 : 0
    when 0.5 then 1
    when 1   then vert ? 0 : 2
    else          vert ? 2 : 0
    end
  end
end

class ImageFont < Font
  attr_reader :chars, :space_width, :char_spacing

  def initialize(img_path, chars, widths, height, space_width, char_spacing: 0, img_extension: 'png')
    @img_path = "fonts/#{img_path}.#{img_extension}"
    @chars = chars
    @height = height
    @space_width = space_width
    @char_spacing = char_spacing

    wa = widths.is_a?(Array)
    @indices = {}
    char_count = 0
    chars.each_true_char do |char, index|
      @indices[char] = index
      char_count += 1
    end
    raise "Wrong widths array size: #{widths.size} vs #{char_count}" if wa && widths.size != char_count

    @rects = []
    x = y = 0
    img_width, img_height = $gtk.calcspritebox(@img_path)
    (0...char_count).each do |i|
      @rects << [x, img_height - y - height, wa ? widths[i] : widths]
      new_x = x + (wa ? widths[i] : widths)
      if i < char_count - 1 && new_x + (wa ? widths[i + 1] : widths) > img_width
        x = 0
        y += height
      else
        x = new_x
      end
    end
  end

  def draw_text_rel(text, x, y, rel_x, rel_y, color, scale: 1, z_index: 0)
    text = text.to_s
    a, r, g, b = hex_to_argb(color)
    if rel_x != 0
      x -= scale * text_width(text) * rel_x
    end
    if rel_y != 0
      y -= scale * height * rel_y
    end

    text.each_true_char do |char|
      if char == ' '
        x += scale * space_width
        next
      end

      i = @indices[char]
      next if i.nil?

      char_width = @rects[i][2]
      Window.output(z_index) << {
        path: @img_path,
        x: x,
        y: Window.height - y - scale * height,
        w: scale * char_width,
        h: scale * height,
        source_x: @rects[i][0],
        source_y: @rects[i][1],
        source_w: char_width,
        source_h: height,
        r: r,
        g: g,
        b: b,
        a: a
      }
      x += (scale * (char_width + char_spacing)).round
    end
  end

  def text_width(text)
    w = 0
    text.each_true_char do |char, i|
      if char == ' '
        w += space_width
      else
        idx = @indices[char]
        w += idx ? @rects[idx][2] : 0
        w += char_spacing if i < text.bytes.size - 1
      end
    end
    w
  end
end

class TextHelper
  def initialize(font, line_spacing: 0, scale: 1)
    @font = font
    @line_spacing = line_spacing
    @scale = scale
  end

  def write_line(text, x, y, alignment = :left, color = 0, alpha: 255, z_index: 0,
                 effect: nil, effect_color: 0, effect_size: 1, effect_alpha: 255,
                 scale: nil)
    scale ||= @scale
    color = (alpha << 24) | color
    rel =
      case alignment
      when :left then 0
      when :center then 0.5
      when :right then 1
      else 0
      end
    if effect
      effect_color = (effect_alpha << 24) | effect_color
      if effect == :border
        @font.draw_text_rel(text, x - effect_size, y - effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x, y - effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x + effect_size, y - effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x + effect_size, y, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x + effect_size, y + effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x, y + effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x - effect_size, y + effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
        @font.draw_text_rel(text, x - effect_size, y, rel, 0, effect_color, scale: scale, z_index: z_index)
      elsif effect == :shadow
        @font.draw_text_rel(text, x + effect_size, y + effect_size, rel, 0, effect_color, scale: scale, z_index: z_index)
      end
    end
    @font.draw_text_rel(text, x, y, rel, 0, color, scale: scale, z_index: z_index)
  end

  def write_breaking(text, x, y, width, alignment = :left, color = 0, alpha: 255, z_index: 0, scale: nil, line_spacing: nil)
    scale ||= @scale
    line_spacing ||= @line_spacing
    color = (alpha << 24) | color
    rel =
      case alignment
      when :left then 0
      when :center then 0.5
      when :right then 1
      else 0
      end
    text.split("\n").each do |p|
      if alignment == :justified
        y = write_paragraph_justified(p, x, y, width, color, scale, line_spacing, z_index)
      else
        y = write_paragraph(p, x, y, width, rel, color, scale, line_spacing, z_index)
      end
    end
  end

  private

  def write_paragraph(text, x, y, width, rel, color, scale, line_spacing, z_index)
    line = ''
    line_width = 0
    text.split(' ').each do |word|
      w = @font.text_width(word)
      if line_width + w * scale > width
        @font.draw_text_rel(line.chop, x, y, rel, 0, color, scale: scale, z_index: z_index)
        line = ''
        line_width = 0
        y += (@font.height + line_spacing) * scale
      end
      line += "#{word} "
      line_width += @font.text_width("#{word} ") * scale
    end
    @font.draw_text_rel(line.chop, x, y, rel, 0, color, scale: scale, z_index: z_index) unless line.empty?
    y + (@font.height + line_spacing) * scale
  end

  def write_paragraph_justified(text, x, y, width, color, scale, line_spacing, z_index)
    space_width = @font.text_width(' ') * scale
    spaces = [[]]
    line_index = 0
    new_x = x
    words = text.split(' ')
    words.each do |word|
      w = @font.text_width(word)
      if new_x + w * scale > x + width
        space = x + width - new_x + space_width
        index = 0
        while space > 0
          spaces[line_index][index] += 1
          space -= 1
          index += 1
          index = 0 if index == spaces[line_index].size - 1
        end

        spaces << []
        line_index += 1

        new_x = x
      end
      new_x += @font.text_width(word) * scale + space_width
      spaces[line_index] << space_width
    end

    index = 0
    spaces.each do |line|
      new_x = x
      line.each do |s|
        @font.draw_text(words[index], new_x, y, color, scale: scale, z_index: z_index)
        new_x += @font.text_width(words[index]) * scale + s
        index += 1
      end
      y += (@font.height + line_spacing) * scale
    end
    y
  end
end
