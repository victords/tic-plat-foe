require_relative '../game'

class StageEndEffect
  TEXT_SCALE = 2
  CHAR_SPACING = 2
  CHAR_DELAY = 5
  FADE_IN_DURATION = 20
  WAVE_DURATION = 28

  attr_reader :dead

  def initialize(result)
    @text = "#{result.to_s.upcase}!"
    @char_widths = @text.chars.map do |char|
      Game.font.text_width(char) * TEXT_SCALE
    end
    @x = (SCREEN_WIDTH - @char_widths.sum - (@text.size - 1) * CHAR_SPACING) / 2
    @y = (SCREEN_HEIGHT - Game.font.height * TEXT_SCALE) / 2
    @text_helper = MiniGL::TextHelper.new(Game.font, 0, TEXT_SCALE, TEXT_SCALE)
    @color = case result
             when :victory then 0x00ffff
             when :defeat  then 0x990000
             else               0xcccccc
             end
    @phase = :fade_in
    @dead = false
    @timer = 0
  end

  def update
    @timer += 1
    case @phase
    when :fade_in
      if @timer >= (@text.size - 1) * CHAR_DELAY + FADE_IN_DURATION + 30
        @phase = :wave
        @timer = 0
      end
    else
      @dead = true if @timer >= (@text.size - 1) * CHAR_DELAY + WAVE_DURATION + 60
    end
  end

  def draw
    x = @x
    is_fade_in = @phase == :fade_in
    @text.each_char.with_index do |c, i|
      frame = @timer - i * CHAR_DELAY
      next if is_fade_in && frame <= 0
      alpha = if is_fade_in
                [(255 * frame.to_f / FADE_IN_DURATION).round, 255].min
              else
                255
              end
      y = if is_fade_in || frame <= 0 || (!is_fade_in && frame >= WAVE_DURATION)
            @y
          else
            @y - (10 - (10.0 / (WAVE_DURATION / 2)**2) * (frame - WAVE_DURATION / 2)**2)
          end
      @text_helper.write_line(c, x, y, :left, @color, alpha, :border, 0, 2, alpha, 1000)
      x += @char_widths[i] + CHAR_SPACING
    end
  end
end
