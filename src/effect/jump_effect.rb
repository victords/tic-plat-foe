require_relative '../constants'

class JumpEffect
  attr_reader :dead

  def initialize(x, y)
    particle_options = {
      x:,
      y:,
      shape: :square,
      scale: 5,
      emission_interval: 60,
      duration: 15,
      alpha_change: :shrink
    }
    @particles = [
      Particles.new(**particle_options.merge(speed: { x: -2.5..-1.5, y: -2.2..-1.8 })).start,
      Particles.new(**particle_options.merge(speed: { x: -1.5..-0.5, y: -2.2..-1.8 })).start,
      Particles.new(**particle_options.merge(speed: { x: 0.5..1.5, y: -2.2..-1.8 })).start,
      Particles.new(**particle_options.merge(speed: { x: 1.5..2.5, y: -2.2..-1.8 })).start,
    ]
    @lifetime = 15
  end

  def update
    @particles.each(&:update)
    @lifetime -= 1
    @dead = true if @lifetime < 0
  end

  def draw
    @particles.each(&:draw)
  end
end
