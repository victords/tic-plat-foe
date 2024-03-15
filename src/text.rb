require_relative 'constants'

include MiniGL

class Text
  class << self
    attr_reader :font

    def init
      @font = Gosu::Font.new(24, name: "#{Res.prefix}font/DejaVuSans.ttf")
    end

    def write(text, x, y, scale = 1, color = DEFAULT_TEXT_COLOR, z = 0)
      @font.draw_text(text, x, y, z, scale, scale, color)
    end

    def write_center(text, x, y, scale = 1, color = DEFAULT_TEXT_COLOR, z = 0)
      @font.draw_text_rel(text, x, y, z, 0.5, 0.5, scale, scale, color)
    end
  end
end
