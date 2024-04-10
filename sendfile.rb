# frozen_string_literal: true

require_relative './valves/network_writer_valve'
require_relative './tunnels/aes_encryption_tunnel'
require_relative './tunnels/file_reader_tunnel'
require_relative './tunnels/progress_logging_tunnel'

t = FileReaderTunnel.new('valves\network_writer_valve.rb')
t = PorgressLoggingTunnel.new(t)
t = AESEncryptionTunnel.new(t, '')
v = ActiveNetworkWriterValve.new(t, ['127.0.0.1', 42])
v.flow
