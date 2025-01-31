require 'app/constants'

class Text
  class << self
    attr_reader :font

    def init
      @font = Font.new(:DejaVuSans, 24)
    end

    def write(text, x, y, scale = 1, color = DEFAULT_TEXT_COLOR, alpha = 255, z = 0)
      color |= (alpha << 24)
      @font.draw_text(text, x, y, color, scale: scale, z_index: z)
    end

    def write_center(text, x, y, scale = 1, color = DEFAULT_TEXT_COLOR, alpha = 255, z = 0)
      color |= (alpha << 24)
      @font.draw_text_rel(text, x, y, 0.5, 0.5, color, scale: scale, z_index: z)
    end
  end
end
