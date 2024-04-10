# frozen_string_literal: true

require_relative '../interface'
require_relative '../commons'
require 'socket'

# The tunnel that reads from network.
class NetworkReaderTunnel < Tunnel
  def initialize(port)
    super()
    server_socket = TCPServer.new('0.0.0.0', port)
    @info = {}
    @conn_socket = server_socket.accept
    server_socket.close
    @closed = false
    _parse_header
  end

  def _parse_header
    return if @conn_socket.closed?

    hello = @conn_socket.read(8)
    raise "Unknown hello line #{hello}" if hello != HELLO_LINE

    until @conn_socket.closed?
      prelude = @conn_socket.read(8)
      command, length = prelude.unpack('a4N')

      raise "Unexpected command #{command} " if command != 'INFO'
      break if length.zero?

      info_line = @conn_socket.read(length)
      k, v = info_line.split(':')
      @info[k] = v
    end
  end

  def drain_out(_n_bytes)
    return '' if @closed

    prelude = @conn_socket.read(8)

    if prelude.nil?
      @closed = true
      @conn_socket.close
      return ''
    end
    command, length = prelude.unpack('a4N')
    raise "Unexpected command #{command} " if command != 'DATA'

    @conn_socket.read(length)
  end

  def info
    @info.dup
  end

  def closed?
    @closed
  end
end
