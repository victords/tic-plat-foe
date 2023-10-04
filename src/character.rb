require_relative 'constants'
require_relative 'pusher'

include MiniGL

class Character < GameObject
  include Pusher

  MOVE_FORCE = 0.5
  JUMP_FORCE = 12
  FRICTION_FACTOR = 0.1

  FRAME_COUNT = {
    idle: 60,
  }.freeze

  def initialize
    super(0, 0, TILE_SIZE - 4, TILE_SIZE - 8, :circle, Vector.new(-2, -8))
    @max_speed.x = 8
    @jump_timer = 0

    @animation_state = :idle
    @animation_frame = 0
    @scale_x = @scale_y = 1
    @offset_x = @offset_y = 0
  end

  def move_to(i, j)
    @x = i * TILE_SIZE + 2
    @y = j * TILE_SIZE + 8
  end

  def animate
    case @animation_state
    when :idle
      deformation = 0.05 * (Math.sin(@animation_frame.to_f / FRAME_COUNT[:idle] * Math::PI))
      @scale_x = 1 + 2 * deformation
      @offset_x = -deformation * @w
      @scale_y = 1 - deformation
      @offset_y = deformation * @h
    end

    @animation_frame += 1
    @animation_frame = 0 if @animation_frame >= FRAME_COUNT[@animation_state]
  end

  def update(stage)
    forces = Vector.new
    if KB.key_down?(Gosu::KB_LEFT)
      forces.x -= MOVE_FORCE
    elsif KB.key_down?(Gosu::KB_RIGHT)
      forces.x += MOVE_FORCE
    else
      forces.x -= FRICTION_FACTOR * @speed.x
    end

    @jump_timer -= 1 if @jump_timer > 0
    if KB.key_pressed?(Gosu::KB_UP)
      @jump_timer = 10
    end
    if @bottom && @jump_timer > 0
      @jump_timer = 0
      forces.y -= JUMP_FORCE
    end

    move_pushing(forces, stage)

    animate
  end

  def draw
    phys_x = @x
    phys_y = @y
    @x += @offset_x
    @y += @offset_y
    super(nil, @scale_x, @scale_y, 255, 0xffffff, nil, nil, 0, true)
    @x = phys_x
    @y = phys_y
  end
end
