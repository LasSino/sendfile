# frozen_string_literal: true

require_relative '../interface'
require_relative '../net_protocol'
require 'socket'

# The tunnel that reads from network.
# This is the passive version, where the reader waits for connection.
class PassiveNetworkReaderTunnel < Tunnel
  def initialize(port)
    super()
    @info = {}
    server_socket = Socket.new(Socket::AF_INET6, Socket::SOCK_STREAM)
    server_socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_V6ONLY, 0)
    server_socket.bind(Addrinfo.tcp('::', port))
    server_socket.listen(1)
    @conn_socket, = server_socket.accept
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

# The tunnel that reads from network.
# This is the active version, where the reader inits connection.
class ActiveNetworkReaderTunnel < Tunnel
  def initialize(destination)
    super()
    @conn_socket = TCPSocket.new(*destination)
    @info = {}
    _parse_header
  end

  def _parse_header
    return if @conn_socket.closed?

    @conn_socket.write(HELLO_LINE)

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
