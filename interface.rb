# frozen_string_literal: true

# A tunnel is a pipe that can emit data stream until closed.
class Tunnel
  def drain_out(n_bytes)
    raise NotImplementedError
  end

  def closed?
    raise NotImplementedError
  end

  def info
    raise NotImplementedError
  end
end

# A tunnel is a pipe that can consume data stream until closed.
class Valve
  attr_accessor :predecessor

  def initialize(predecessor)
    @predecessor = predecessor
  end

  def flow
    raise NotImplementedError
  end

  def info
    raise NotImplementedError
  end
end
