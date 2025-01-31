require 'app/text'

class LevelEndEffect
  TEXT_SCALE = 2
  CHAR_SPACING = 2
  WAVE_DURATION = 28

  attr_reader :dead

  def initialize(result)
    @result = result
    @text = "#{result.to_s.upcase}!"
    @char_widths = @text.chars.map do |char|
      Text.font.text_width(char) * TEXT_SCALE
    end
    @x = (SCREEN_WIDTH - @char_widths.sum - (@text.size - 1) * CHAR_SPACING) / 2
    @y = (SCREEN_HEIGHT - Text.font.height * TEXT_SCALE) / 2
    @text_helper = TextHelper.new(Text.font, scale: TEXT_SCALE)
    @color, @char_delay, @fade_in_duration =
      case result
      when :victory
        [0x00ffff, 5, 30]
      else
        [0x990000, 15, 1]
      end
    @phase = :fade_in
    @dead = false
    @timer = 0
  end

  def update
    @timer += 1
    case @phase
    when :fade_in
      if @timer >= (@text.size - 1) * @char_delay + @fade_in_duration + 15
        if @result == :victory
          @phase = :wave
          @timer = 0
        else
          @dead = true
        end
      end
    else
      @dead = true if @timer >= (@text.size - 1) * @char_delay + WAVE_DURATION + 60
    end
  end

  def draw
    x = @x
    is_fade_in = @phase == :fade_in
    @text.each_char.with_index do |c, i|
      frame = @timer - i * @char_delay
      next if is_fade_in && frame <= 0
      alpha = if is_fade_in
                [(255 * frame.to_f / @fade_in_duration).round, 255].min
              else
                255
              end
      y = if is_fade_in || frame <= 0 || (!is_fade_in && frame >= WAVE_DURATION)
            @y
          else
            @y - (10 - (10.0 / (WAVE_DURATION / 2)**2) * (frame - WAVE_DURATION / 2)**2)
          end
      @text_helper.write_line(c, x, y, :left, @color, alpha: alpha, effect: :border, effect_color: 0, effect_size: 2, effect_alpha: alpha, z_index: 1000)
      x += @char_widths[i] + CHAR_SPACING
    end
  end
end
