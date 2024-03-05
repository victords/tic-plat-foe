require_relative 'constants'
require_relative 'pusher'
require_relative 'effect/jump_effect'

include MiniGL

class Character < GameObject
  include Pusher

  MOVE_FORCE = 0.5
  JUMP_FORCE = 12
  FRICTION_FACTOR = 0.1

  FRAME_COUNT = {
    idle: 60,
    walking: 40,
    jumping: 40,
  }.freeze

  def initialize
    super(0, 0, TILE_SIZE - 4, TILE_SIZE - 8, :circle, Vector.new(-2, -8))
    @max_speed.x = 4
    @jump_timer = 0

    @scale_x = @scale_y = 1
    @offset_x = @offset_y = 0
    @animation_frame = 0
    @animation_state = :idle

    particle_options = {
      source: self,
      source_offset_y: @h - 5,
      shape: :square,
      scale: 5,
      emission_interval: 5,
      duration: 15,
      alpha_change: :shrink,
    }
    @particles_left = Particles.new(**particle_options.merge(
      source_offset_x: @w / 2 + 15,
      speed: { x: 3, y: -1..1 }
    ))
    @particles_right = Particles.new(**particle_options.merge(
      source_offset_x: @w / 2 - 15,
      speed: { x: -3, y: -1..1 }
    ))
  end

  def move_to(i, j)
    @x = i * TILE_SIZE + 2
    @y = j * TILE_SIZE + 8
    @speed = Vector.new
  end

  def transition_animation(state)
    @animation_frame = ((@animation_frame.to_f / FRAME_COUNT[@animation_state]) * FRAME_COUNT[state]).round
    @animation_state = state
  end

  def reset_animation(state)
    @animation_frame = 0
    @animation_state = state
  end

  def animate
    factor = case @animation_state
             when :idle
               0.05
             when :walking
               0.1
             when :jumping
               -0.1
             end
    deformation = factor * (Math.sin(@animation_frame.to_f / FRAME_COUNT[@animation_state] * Math::PI))
    @scale_x = 1 + 2 * deformation
    @offset_x = -deformation * @w
    @scale_y = 1 - deformation
    @offset_y = deformation * @h

    @animation_frame += 1
    @animation_frame = 0 if @animation_frame >= FRAME_COUNT[@animation_state]
  end

  def update(level)
    forces = Vector.new
    if KB.key_down?(Gosu::KB_LEFT)
      forces.x -= MOVE_FORCE
      @particles_left.start if @bottom && !@particles_left.emitting?
    elsif KB.key_down?(Gosu::KB_RIGHT)
      forces.x += MOVE_FORCE
      @particles_right.start if @bottom && !@particles_right.emitting?
    else
      forces.x -= FRICTION_FACTOR * @speed.x
      @particles_left.stop
      @particles_right.stop
    end

    @jump_timer -= 1 if @jump_timer > 0
    if KB.key_pressed?(Gosu::KB_UP)
      @jump_timer = 10
    end
    if @bottom && @jump_timer > 0
      @jump_timer = 0
      forces.y -= JUMP_FORCE
      reset_animation(:jumping)
      level.add_effect(JumpEffect.new(@x + @w / 2, @y + @h))
      @particles_left.stop
      @particles_right.stop
    end

    prev_bottom = @bottom
    move_pushing(forces, level)
    if @bottom && !prev_bottom
      reset_animation(:idle)
    end

    if @speed.x.abs >= 0.1 && @animation_state == :idle
      transition_animation(:walking)
    elsif @speed.x.abs < 0.1 && @animation_state == :walking
      transition_animation(:idle)
    end
    animate

    @particles_left.update
    @particles_right.update
  end

  def draw
    phys_x = @x
    phys_y = @y
    @x += @offset_x
    @y += @offset_y
    super(nil, @scale_x, @scale_y)
    @x = phys_x
    @y = phys_y
    @particles_left.draw
    @particles_right.draw
  end
end
