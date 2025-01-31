class Image
  attr_reader :path, :width, :height, :source_x, :source_y, :source_w, :source_h

  def initialize(path, extension = 'png', source_x: nil, source_y: nil, source_w: nil, source_h: nil)
    @path = "sprites/#{path}.#{extension}"
    @width, @height =
      if source_w && source_h
        [source_w, source_h]
      else
        $gtk.calcspritebox(@path)
      end
    @source_x = source_x
    @source_y = source_y
    @source_w = source_w
    @source_h = source_h
  end

  def draw(x, y, color: 0xffffffff, scale_x: 1, scale_y: 1, angle: 0, flip: nil, z_index: 0)
    a, r, g, b = hex_to_argb(color)
    w = scale_x * (source_w || width)
    h = scale_y * (source_h || height)
    props = {
      path: @path,
      x: x,
      y: Window.height - y - h,
      w: w,
      h: h,
      r: r,
      g: g,
      b: b,
      a: a,
      angle: angle,
      flip_horizontally: flip == :horiz,
      flip_vertically: flip == :vert
    }
    if source_x
      props[:source_x] = source_x
      props[:source_y] = source_y
      props[:source_w] = source_w
      props[:source_h] = source_h
    end
    Window.output(z_index) << props
  end
end

class Tileset
  include Enumerable

  attr_reader :tile_count, :tile_width, :tile_height

  def initialize(path, cols, rows, extension = 'png')
    @tile_count = cols * rows
    width, height = $gtk.calcspritebox("sprites/#{path}.#{extension}")
    @tile_width = width.idiv(cols)
    @tile_height = height.idiv(rows)
    @tiles = (0...tile_count).map do |i|
      Image.new(path, extension,
                source_x: (i % cols) * tile_width,
                source_y: height - (i.idiv(cols) + 1) * tile_height,
                source_w: tile_width,
                source_h: tile_height)
    end
  end

  def [](index)
    @tiles[index]
  end

  def each(&block)
    @tiles.each(&block)
  end
end
