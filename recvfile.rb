# frozen_string_literal: true

require_relative './valves/file_writer_valve'
require_relative './tunnels/aes_decryption_tunnel'
require_relative './tunnels/network_reader_tunnel'
require_relative './tunnels/progress_logging_tunnel'

t = PassiveNetworkReaderTunnel.new(42)
t = AESDecryptionTunnel.new(t, '')
t = PorgressLoggingTunnel.new(t)
v = FileWriterValve.new(t, '.')
v.flow
