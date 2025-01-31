class Particles
  SUPPORTED_SHAPES = %i[square]

  def initialize(**options)
    raise "Particles must have either a shape or an image!" if options[:shape].nil? && options[:img].nil?
    raise "Unsupported shape '#{options[:shape]}'" if options[:shape] && !SUPPORTED_SHAPES.include?(options[:shape])

    @options = DEFAULT_OPTIONS.merge(options)
    @x = (@options[:source]&.x || @options[:x]) + @options[:source_offset_x]
    @y = (@options[:source]&.y || @options[:y]) + @options[:source_offset_y]

    @particles = []
    @emitting = false
  end

  def start
    set_emission_time
    @timer = @emission_time
    @emitting = true
    self
  end

  def stop
    @emitting = false
  end

  def move_to(x, y)
    @x = x
    @y = y
  end

  def emitting?
    @emitting
  end

  def count
    @particles.size
  end

  def update
    @particles.each do |particle|
      particle.update
      @particles.delete(particle) if particle.dead?
    end
    return unless @emitting

    if @options[:source]
      @x = @options[:source].x + @options[:source_offset_x]
      @y = @options[:source].y + @options[:source_offset_y]
    end

    @timer += 1
    if @timer >= @emission_time
      count = @options[:emission_rate].is_a?(Range) ? Numeric.rand(@options[:emission_rate]) : @options[:emission_rate]
      count.times do
        x = @options[:area] ? @x + Numeric.rand * @options[:area].x : @x + @options[:spread] * (Numeric.rand - 0.5)
        y = @options[:area] ? @y + Numeric.rand * @options[:area].y : @y + @options[:spread] * (Numeric.rand - 0.5)
        @particles << Particle.new(x: x,
                                   y: y,
                                   duration: @options[:duration],
                                   shape: @options[:shape],
                                   img: @options[:img],
                                   **@options.slice(*PARTICLE_OPTIONS))
      end
      set_emission_time
      @timer = 0
    end
  end

  def draw(map = nil, z_index = 0)
    @particles.each do |particle|
      particle.draw(map, z_index)
    end
  end

  private

  DEFAULT_OPTIONS = {
    x: 0,
    y: 0,
    source: nil,
    source_offset_x: 0,
    source_offset_y: 0,
    emission_interval: 10,
    emission_rate: 1,
    duration: 30,
    shape: nil,
    img: nil,
    spread: 0,
    scale: 1,
    scale_change: nil,
    scale_min: 0,
    scale_max: 1,
    scale_inflection: 0.5,
    alpha: 255,
    alpha_change: nil,
    alpha_min: 0,
    alpha_max: 255,
    alpha_inflection: 0.5,
    angle: nil,
    rotation: nil,
    speed: nil,
    color: 0xffffff,
    round_position: true,
  }.freeze

  PARTICLE_OPTIONS = %i[
    scale
    scale_change
    scale_min
    scale_max
    scale_inflection
    alpha
    alpha_change
    alpha_min
    alpha_max
    alpha_inflection
    angle
    rotation
    speed
    color
    round_position
  ].freeze

  def set_emission_time
    interval = @options[:emission_interval]
    @emission_time = interval.is_a?(Range) ? Numeric.rand(interval) : interval
  end

  class Particle
    def initialize(x:, y:, duration:, shape: nil, img: nil, **options)
      @x = x
      @y = y
      @duration = duration
      @shape = shape
      @img = img
      @options = DEFAULT_OPTIONS.slice(*PARTICLE_OPTIONS).merge(options)
      @elapsed_time = 0

      if @options[:angle].is_a?(Range)
        @angle = Numeric.rand(@options[:angle])
      elsif @options[:angle].is_a?(Numeric)
        @angle = @options[:angle]
      end
      @angle ||= 0

      if @options[:speed].is_a?(Hash)
        speed_x = @options[:speed][:x].is_a?(Range) ? Numeric.rand(@options[:speed][:x]) : (@options[:speed][:x] || 0)
        speed_y = @options[:speed][:y].is_a?(Range) ? Numeric.rand(@options[:speed][:y]) : (@options[:speed][:y] || 0)
        @speed = Vector.new(speed_x, speed_y)
      elsif @options[:speed].is_a?(Vector)
        @speed = @options[:speed]
      end

      init_variable_property(:scale)
      init_variable_property(:alpha)
    end

    def init_variable_property(name)
      ivar_name = "@#{name}".to_sym
      case @options["#{name}_change".to_sym]
      when :grow, :alternate
        instance_variable_set(ivar_name, @options["#{name}_min".to_sym])
      when :shrink
        instance_variable_set(ivar_name, @options["#{name}_max".to_sym])
      else
        instance_variable_set(ivar_name, @options[name.to_sym])
      end
    end

    def update_variable_property(name)
      ivar_name = "@#{name}".to_sym
      min = @options["#{name}_min".to_sym]
      max = @options["#{name}_max".to_sym]
      case @options["#{name}_change".to_sym]
      when :grow
        instance_variable_set(ivar_name, min + (@elapsed_time.to_f / @duration) * (max - min))
      when :shrink
        instance_variable_set(ivar_name, max - (@elapsed_time.to_f / @duration) * (max - min))
      when :alternate
        inflection_point = (@options["#{name}_inflection".to_sym] * @duration).round
        if @elapsed_time >= inflection_point
          instance_variable_set(ivar_name, min + (@duration - @elapsed_time).to_f / (@duration - inflection_point) * (max - min))
        else
          instance_variable_set(ivar_name, min + (@elapsed_time.to_f / inflection_point) * (max - min))
        end
      end
    end

    def dead?
      @elapsed_time >= @duration
    end

    def update
      if @options[:rotation] && !@img.nil?
        @angle += @options[:rotation]
        @angle -= 360 if @angle >= 360
      end

      if @speed
        @x += @speed.x
        @y += @speed.y
      end

      update_variable_property(:scale) if @options[:scale_change]
      if @options[:alpha_change]
        update_variable_property(:alpha)
        @alpha = @alpha.round
      end

      @elapsed_time += 1
    end

    def draw(map, z_index)
      x = @x - (map&.cam&.x || 0)
      y = @y - (map&.cam&.y || 0)
      if @options[:round_position]
        x = x.round
        y = y.round
      end
      color = (@alpha << 24) | @options[:color]
      if @img
        @img.draw(x - @img.width * @scale * 0.5, y - @img.height * @scale * 0.5, color: color, angle: @angle, scale_x: @scale, scale_y: @scale, z_index: z_index)
      else
        case @shape
        when :square
          Window.draw_rect(@x - @scale * 0.5, @y - @scale * 0.5, @scale, @scale, color, z_index)
        end
      end
    end
  end
end
