require_relative 'thumbnail'
require_relative 'character'

module LevelSelect
  class Map
    CAM_SNAP_THRESHOLD = 2
    ZOOMED_IN_TILE_SIZE = L_S_MAX_ZOOM * TILE_SIZE

    LEVELS_LAYOUT = [
      [2, 0],
      [2, 2],
      [4, 2],
      [6, 2],
      [6, 4],
      [6, 7],
    ].freeze

    attr_writer :on_select

    def initialize(last_level)
      @last_level = last_level

      @map = MiniGL::Map.new(ZOOMED_IN_TILE_SIZE, ZOOMED_IN_TILE_SIZE, TILES_X, TILES_Y)

      @elements = Array.new(TILES_X) { Array.new(TILES_Y) }
      @thumbnails = []
      LEVELS_LAYOUT[0...last_level].each_with_index do |(i, j), index|
        add_thumbnail(index + 1, i, j, index + 1 < last_level)
      end
      @thumbnails[0].on_fade_end = method(:on_thumbnail_fade_end)

      @cursor_pos = LEVELS_LAYOUT[0]
      @character = Character.new(*@cursor_pos)
      @character.on_fade_end = method(:on_character_fade_end)
      level_under_cursor&.select

      @zoom = L_S_MAX_ZOOM
      @state = :default
    end

    def last_level=(new_value)
      return unless new_value > @last_level

      @thumbnails[@last_level - 1].passed!
      @last_level = new_value
      (i, j) = LEVELS_LAYOUT[new_value - 1]
      add_thumbnail(new_value, i, j, false)
    end

    def update
      if @camera_target
        delta_x = @camera_target.x - @map.cam.x
        delta_y = @camera_target.y - @map.cam.y
        if delta_x.abs <= CAM_SNAP_THRESHOLD && delta_y.abs <= CAM_SNAP_THRESHOLD
          @map.set_camera(@camera_target.x, @camera_target.y)
          @camera_target = nil
        else
          @map.move_camera(delta_x * INTERPOLATION_RATE, delta_y * INTERPOLATION_RATE)
        end
      end

      if @target_zoom
        delta = @target_zoom - @zoom
        if delta.abs < 0.01
          @zoom = @target_zoom
          @target_zoom = nil
          if @state == :zooming_out_zoom
            @character.fade(:in)
            @state = :zoomed_out
          else
            @thumbnails.each { |t| t.fade(:in) }
            @character.fade(:in)
            @state = :default
          end
        else
          @zoom += delta * INTERPOLATION_RATE
        end
      end

      if KB.key_pressed?(Gosu::KB_Z) && @camera_target.nil?
        if @state == :default
          @thumbnails.each { |t| t.fade(:out) }
          @character.fade(:out)
          @state = :zooming_out_fade
        elsif @state == :zoomed_out
          @character.fade(:out)
          @state = :zooming_in_fade
        end
      elsif KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_SPACE)
        @on_select.call(level_under_cursor.id) if @state == :default && level_under_cursor
      elsif KB.key_pressed?(Gosu::KB_UP) && @cursor_pos[1] > 0
        move_cursor(:up)
      elsif KB.key_pressed?(Gosu::KB_RIGHT) && @cursor_pos[0] < TILES_X - 1
        move_cursor(:rt)
      elsif KB.key_pressed?(Gosu::KB_DOWN) && @cursor_pos[1] < TILES_Y - 1
        move_cursor(:dn)
      elsif KB.key_pressed?(Gosu::KB_LEFT) && @cursor_pos[0] > 0
        move_cursor(:lf)
      end

      @thumbnails.each(&:update)
      @character.update
    end

    def draw
      (1...TILES_X).each do |i|
        x = i * @zoom * TILE_SIZE - 1 - @map.cam.x
        G.window.draw_rect(x, 0, 2, SCREEN_HEIGHT, GRID_COLOR, 0) if x >= -1 && x < SCREEN_WIDTH
      end
      (1...TILES_Y).each do |i|
        y = i * @zoom * TILE_SIZE - 1 - @map.cam.y
        G.window.draw_rect(0, y, SCREEN_WIDTH, 2, GRID_COLOR, 0) if y >= -1 && y < SCREEN_HEIGHT
      end
      @thumbnails.each { |t| t.draw(@map, @zoom) }
      @character.draw(@map, @zoom)
    end

    private

    def add_thumbnail(level, i, j, passed)
      @elements[i][j] = Thumbnail.new(level, i, j, passed)
      @thumbnails << @elements[i][j]
    end

    def level_under_cursor
      @elements[@cursor_pos[0]][@cursor_pos[1]]
    end

    def move_cursor(dir)
      level_under_cursor&.deselect
      case dir
      when :up
        @cursor_pos[1] -= 1
        @character.move(0, -1)
      when :rt
        @cursor_pos[0] += 1
        @character.move(1, 0)
      when :dn
        @cursor_pos[1] += 1
        @character.move(0, 1)
      else
        @cursor_pos[0] -= 1
        @character.move(-1, 0)
      end
      level_under_cursor&.select

      screen_pos = @map.get_screen_pos(*@cursor_pos)
      move_x = 0
      move_y = 0
      if screen_pos.x >= 4 * ZOOMED_IN_TILE_SIZE
        move_x = 2 * ZOOMED_IN_TILE_SIZE
      elsif screen_pos.x < ZOOMED_IN_TILE_SIZE
        move_x = -2 * ZOOMED_IN_TILE_SIZE
      end
      if screen_pos.y >= 3 * ZOOMED_IN_TILE_SIZE
        move_y = 2 * ZOOMED_IN_TILE_SIZE
      elsif screen_pos.y < ZOOMED_IN_TILE_SIZE
        move_y = -2 * ZOOMED_IN_TILE_SIZE
      end
      move_camera(move_x, move_y)
    end

    def move_camera(x, y)
      return if x.zero? && y.zero?

      target_x = (@camera_target&.x || @map.cam.x) + x
      target_y = (@camera_target&.y || @map.cam.y) + y
      set_camera(target_x, target_y)
    end

    def set_camera(x, y)
      target_x = [[x, 0].max, @map.instance_variable_get(:@max_x)].min
      target_y = [[y, 0].max, @map.instance_variable_get(:@max_y)].min
      return if target_x == @map.cam.x && target_y == @map.cam.y

      @camera_target = Vector.new(target_x, target_y)
    end

    def on_thumbnail_fade_end
      return unless @state == :zooming_out_fade

      @target_zoom = 1
      set_camera(0, 0)
      @state = :zooming_out_zoom
    end

    def on_character_fade_end
      if @state == :zooming_in_fade
        @target_zoom = L_S_MAX_ZOOM
        set_camera((@cursor_pos[0] - 2) * ZOOMED_IN_TILE_SIZE, (@cursor_pos[1] - 1) * ZOOMED_IN_TILE_SIZE)
        @character.move_to_zoomed_in(*@cursor_pos)
        @state = :zooming_in_zoom
      else
        @character.move_to_zoomed_out(*@cursor_pos)
      end
    end
  end
end
