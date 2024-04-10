# frozen_string_literal: true

require_relative '../interface'

# The tunnel that reads from a file.
class FileReaderTunnel < Tunnel
  def initialize(file_name)
    super()
    @file = File.open(file_name, 'rb')
    @info = {
      'name' => File.basename(@file),
      'size' => File.size(@file)
    }
    @closed = false
  end

  def drain_out(n_bytes)
    raise 'Tunnel closed because reached end of file.' if @closed

    buf = @file.read(n_bytes)
    if @file.eof?
      @file.close
      @closed = true
    end
    buf
  end

  def info
    @info.dup
  end

  def closed?
    @closed
  end
end
