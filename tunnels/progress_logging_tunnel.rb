# frozen_string_literal: true

require_relative '../interface'
require 'ruby-progressbar'

# The tunnel that logs the progress.
class PorgressLoggingTunnel < Tunnel
  def initialize(predecessor)
    super()
    @predecessor = predecessor
    @closed = false
    puts info['name']
    @progressbar = ProgressBar.create(title: info['name'], total: info['size'].to_i,
                                      rate_scale: ->(rate) { rate / 1024 }, format: '<%B> %P %E - %R KB/s')
  end

  def drain_out(n_bytes)
    @closed = true if @predecessor.closed?
    return '' if @closed

    data = @predecessor.drain_out(n_bytes)
    @progressbar.progress += data.bytesize
    data
  end

  def info
    @predecessor.info.dup
  end

  def closed?
    @closed
  end
end
