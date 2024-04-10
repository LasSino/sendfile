# frozen_string_literal: true

require_relative '../interface'
require_relative '../commons'
require 'socket'

MTU_LIMIT = 1024

# A tunnel is a pipe that can consume data stream until closed.
class NetworkWriterValve < Valve
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
