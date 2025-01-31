class Sound
  attr_reader :path, :key

  def initialize(path, extension: 'wav')
    @path = "sounds/#{path}.#{extension}"
    @key = "#{path}_#{object_id}"
  end

  def play(volume = 1.0, looping: false)
    $args.audio[@key] = {
      input: @path,
      gain: volume,
      looping: looping
    }
  end

  def stop
    $args.audio[@key] = nil
  end

  def pause
    return if $args.audio[@key].nil?
    $args.audio[@key][:paused] = true
  end

  def resume
    return if $args.audio[@key].nil?
    $args.audio[@key][:paused] = false
  end

  def volume=(value)
    return if $args.audio[@key].nil?
    $args.audio[@key][:gain] = value
  end

  def playing?
    !$args.audio[@key].nil? && !$args.audio[@key][:paused]
  end
end

class Song < Sound
  @@current_song = nil

  def initialize(path, extension: 'ogg')
    super(path, extension: extension)
  end

  def play(volume = 1.0, looping: true, stop_current: true)
    return if playing?

    @@current_song&.stop if stop_current
    super(volume, looping: looping)
    @@current_song = self
  end

  def stop
    super
    @@current_song = nil
  end

  def self.current_song
    @@current_song
  end
end
