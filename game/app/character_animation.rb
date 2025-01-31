module CharacterAnimation
  FRAME_COUNT = {
    idle: 60,
    walking: 40,
    jumping: 40,
  }.freeze

  def init_animation
    @scale_x = @scale_y = 1
    @offset_x = @offset_y = 0
    @animation_frame = 0
    @animation_state = :idle
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

  def with_animation_offsets
    phys_x = @x
    phys_y = @y
    @x += @offset_x
    @y += @offset_y
    yield
    @x = phys_x
    @y = phys_y
  end
end
