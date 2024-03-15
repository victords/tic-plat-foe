require_relative "constants"
require_relative "text"
require_relative "game"

include MiniGL

class EditorLevel < Level
  def initialize(id = nil)
    @elements = Array.new(SCREEN_WIDTH / TILE_SIZE) { Array.new(SCREEN_HEIGHT / TILE_SIZE) { "_" } }

    if id
      super(id)
      @elements[@start_point.x][@start_point.y] = "s"
      @blocks[2..].each do |b|
        @elements[b.x / TILE_SIZE][b.y / TILE_SIZE] = "#"
      end
      @passable_blocks.each do |b|
        @elements[b.x / TILE_SIZE][b.y / TILE_SIZE] = "-"
      end
      @marks.each do |m|
        @elements[m.x / TILE_SIZE][m.y / TILE_SIZE] = mark_type_to_char(m.type)
      end
      return
    end

    @map = Map.new(TILE_SIZE, TILE_SIZE, SCREEN_WIDTH / TILE_SIZE, SCREEN_HEIGHT / TILE_SIZE, SCREEN_WIDTH, SCREEN_HEIGHT)
    @blocks = [
      Block.new(-1, 0, 1, SCREEN_HEIGHT),
      Block.new(SCREEN_WIDTH, 0, 1, SCREEN_HEIGHT),
    ]
    @passable_blocks = []
    @marks = []
  end

  def place(obj_type, i, j)
    case obj_type
    when "s"
      @elements[@start_point.x][@start_point.y] = "_" if @start_point
      @start_point = Vector.new(i, j)
    when "o"
      @marks << Mark.new(:circle, i, j)
    when "x"
      @marks << Mark.new(:x, i, j)
    when "["
      @marks << Mark.new(:square, i, j)
    when "#"
      @blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    when "-"
      @passable_blocks << Block.new(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE, true)
    end

    erase(i, j, obj_type)
  end

  def erase(i, j, new_obj_type = "_")
    prev_element = @elements[i][j]
    case prev_element
    when "o", "x", "["
      @marks.delete(@marks.find { |m| m.x / TILE_SIZE == i && m.y / TILE_SIZE == j })
    when "#"
      @blocks.delete(@blocks.find { |b| b.x / TILE_SIZE == i && b.y / TILE_SIZE == j })
    when "-"
      @passable_blocks.delete(@passable_blocks.find { |b| b.x / TILE_SIZE == i && b.y / TILE_SIZE == j })
    end

    @elements[i][j] = new_obj_type
  end

  def fill(i, j, origin = :none)
    return if i < 0 || i >= @map.size.x || j < 0 || j >= @map.size.y
    return unless @elements[i][j] == "_" || @elements[i][j] == "#" && origin == :none

    place("#", i, j)
    fill(i, j - 1, :down) unless origin == :up
    fill(i + 1, j, :left) unless origin == :right
    fill(i, j + 1, :up) unless origin == :down
    fill(i - 1, j, :right) unless origin == :left
  end

  def save(number)
    File.open("#{Res.prefix}level/#{number}", "w+") do |f|
      f.write("#{@title}\n")
      (0...@map.size.y).each do |j|
        f.write("#{@elements.map { |line| line[j] }.join}\n")
      end
    end
  end

  def draw
    (1...@map.size.x).each do |i|
      G.window.draw_rect(i * TILE_SIZE - 1, 0, 2, SCREEN_HEIGHT, GRID_COLOR, 0)
    end
    (1...@map.size.y).each do |j|
      G.window.draw_rect(0, j * TILE_SIZE - 1, SCREEN_WIDTH, 2, GRID_COLOR, 0)
    end
    @map.foreach do |i, j, x, y|
      block = @blocks.any? { |o| o.x == x && o.y == y }
      block_rt = @blocks.any? { |o| o.x == x + TILE_SIZE && o.y == y }
      block_dn = @blocks.any? { |o| o.x == x && o.y == y + TILE_SIZE }
      rt = i < @map.size.x - 1 && ((block && !block_rt) || (!block && block_rt))
      dn = j < @map.size.y - 1 && ((block && !block_dn) || (!block && block_dn))
      G.window.draw_rect(x + TILE_SIZE - 1, y, 2, TILE_SIZE, WALL_COLOR, 0) if rt
      G.window.draw_rect(x, y + TILE_SIZE - 1, TILE_SIZE, 2, WALL_COLOR, 0) if dn
    end
    @passable_blocks.each do |b|
      G.window.draw_rect(b.x + 4, b.y - 1, TILE_SIZE - 8, 2, WALL_COLOR, 0)
    end
    @marks.each(&:draw)

    return unless @start_point
    Text.write_center("S", (@start_point.x + 0.5) * TILE_SIZE, (@start_point.y + 0.5) * TILE_SIZE)
  end

  private

  def mark_type_to_char(type)
    case type
    when :circle
      return "o"
    when :x
      return "x"
    when :square
      return "["
    end
  end
end

class Editor < GameWindow
  def initialize
    super(920, 600, false)
    Res.prefix = "#{File.expand_path(__FILE__).split("/")[0..-3].join("/")}/data"
    Text.init
    Game.init

    @level_number = 1
    @level = EditorLevel.new
    button_props = {
      x: SCREEN_WIDTH,
      width: 40,
      height: 40,
      font: Text.font,
      text_color: 0xffffff,
      over_text_color: 0xdddddd,
      down_text_color: 0xbbbbbb,
    }
    @buttons = [
      Button.new(button_props.merge(y: 10, text: "S")) { @action = "s" },
      Button.new(button_props.merge(y: 60, text: "#")) { @action = "#" },
      Button.new(button_props.merge(y: 110, text: "-")) { @action = "-" },
      Button.new(button_props.merge(y: 160, text: "O")) { @action = "o" },
      Button.new(button_props.merge(y: 210, text: "X")) { @action = "x" },
      Button.new(button_props.merge(y: 260, text: "□")) { @action = "[" },
      Button.new(button_props.merge(y: 360, text: "<")) { @level_number = (@level_number - 2) % 10 + 1 },
      Button.new(button_props.merge(x: SCREEN_WIDTH + 80, y: 360, text: ">")) { @level_number = @level_number % 10 + 1 },
      Button.new(button_props.merge(x: SCREEN_WIDTH + 40, y: 410, text: 'load')) { @level = EditorLevel.new(@level_number) },
      Button.new(button_props.merge(x: SCREEN_WIDTH + 40, y: 460, text: 'save')) { @level.save(@level_number) },
    ]
  end

  def update
    Mouse.update
    @buttons.each(&:update)
    return unless Mouse.over?(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    col = Mouse.x / TILE_SIZE
    row = Mouse.y / TILE_SIZE
    if Mouse.double_click?(:left) && @action == "#"
      @level.fill(col, row)
    elsif Mouse.button_down?(:left)
      @level.place(@action, col, row) if @action
    elsif Mouse.button_down?(:right)
      @level.erase(col, row)
    end
  end

  def draw
    @level.draw
    G.window.draw_rect(SCREEN_WIDTH, 0, 120, SCREEN_HEIGHT, 0x80ffffff)
    @buttons.each(&:draw)
    Text.write_center(@level_number.to_s, SCREEN_WIDTH + 60, 380)
  end
end

Editor.new.show
