# frozen_string_literal: true

require_relative '../interface'
require 'socket'

BUF_SIZE = 1024

# A tunnel is a pipe that can consume data stream until closed.
class FileWriterValve < Valve
  def initialize(predecessor, base_dir = '.')
    super(predecessor)
    @base_dir = base_dir
  end

  def flow
    file_name = @predecessor.info['name']
    @file = File.open(File.join(@base_dir, file_name), 'wb')

    until @predecessor.closed?
      data = @predecessor.drain_out(BUF_SIZE)
      @file.write(data)
    end

    @file.close
  end

  def info
    @predecessor.info
  end
end
