# frozen_string_literal: true

require_relative '../interface'
require_relative '../net_protocol'
require 'socket'

MTU_LIMIT = 1024

# A tunnel is a pipe that can consume data stream until closed.
# This is the active version that initializes a connection.
class ActiveNetworkWriterValve < Valve
  def initialize(predecessor, destination)
    super(predecessor)
    @conn_socket = TCPSocket.new(*destination)
  end

  def _parse_prelude(type, payload)
    s = payload.bytesize
    case type
    when :info
      ['INFO', s].pack('a4N')
    when :data
      ['DATA', s].pack('a4N')
    else
      raise "Unsupported packet type: #{type}."
    end
  end

  def flow
    @conn_socket.write(HELLO_LINE)
    @predecessor.info.each do |k, v|
      info_payload = "#{k}:#{v}"
      @conn_socket.write(_parse_prelude(:info, info_payload))
      @conn_socket.write(info_payload)
    end
    @conn_socket.write(_parse_prelude(:info, ''))

    until @predecessor.closed?
      data = @predecessor.drain_out(MTU_LIMIT)
      @conn_socket.write(_parse_prelude(:data, data))
      @conn_socket.write(data)
    end

    @conn_socket.close
  end

  def info
    @predecessor.info
  end
end

# A tunnel is a pipe that can consume data stream until closed.
# This is the passive version that waits for a connection.
class PassiveNetworkWriterValve < Valve
  def initialize(predecessor, port)
    super(predecessor)
    server_socket = Socket.new(Socket::AF_INET6, Socket::SOCK_STREAM)
    server_socket.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_V6ONLY, 0)
    server_socket.bind(Addrinfo.tcp('::', port))
    server_socket.listen(1)
    @conn_socket, = server_socket.accept
    server_socket.close
  end

  def _parse_prelude(type, payload)
    s = payload.bytesize
    case type
    when :info
      ['INFO', s].pack('a4N')
    when :data
      ['DATA', s].pack('a4N')
    else
      raise "Unsupported packet type: #{type}."
    end
  end

  def flow
    hello = @conn_socket.read(8)
    raise "Unknown hello line #{hello}" if hello != HELLO_LINE

    @predecessor.info.each do |k, v|
      info_payload = "#{k}:#{v}"
      @conn_socket.write(_parse_prelude(:info, info_payload))
      @conn_socket.write(info_payload)
    end
    @conn_socket.write(_parse_prelude(:info, ''))

    until @predecessor.closed?
      data = @predecessor.drain_out(MTU_LIMIT)
      @conn_socket.write(_parse_prelude(:data, data))
      @conn_socket.write(data)
    end

    @conn_socket.close
  end

  def info
    @predecessor.info
  end
end
