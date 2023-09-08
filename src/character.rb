require_relative 'constants'

include MiniGL

class Character < GameObject
  MOVE_FORCE = 0.5
  JUMP_FORCE = 12
  FRICTION_FACTOR = 0.1

  def initialize
    super(0, 0, TILE_SIZE - 8, TILE_SIZE - 8, :circle, Vector.new(-4, -8))
    @max_speed.x = 8
    @jump_timer = 0
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

    move(forces, stage.obstacles, [])
  end

  def draw
    super(nil, 1, 1, 255, 0xffffff, nil, nil, 0, true)
  end
end
