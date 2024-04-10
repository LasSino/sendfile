# frozen_string_literal: true

require 'openssl'
require 'base64'
require_relative '../interface'

# The tunnel that performs AES encryption on the data.
class AESEncryptionTunnel < Tunnel
  def initialize(predecessor, password)
    super()
    @predecessor = predecessor
    @info = {}
    @closed = false
    _init_cipher(password)
  end

  def _init_cipher(password)
    @cipher = OpenSSL::Cipher.new('aes-128-ctr').encrypt
    iv = @cipher.random_iv
    salt = OpenSSL::Random.random_bytes(32)
    @cipher.key = OpenSSL::KDF.pbkdf2_hmac(
      password,
      salt: salt, iterations: 2 << 16,
      length: @cipher.key_len, hash: 'SHA256'
    )
    @info['key_salt'] = Base64.strict_encode64(salt)
    @info['cipher_iv'] = Base64.strict_encode64(iv)
  end

  def drain_out(n_bytes)
    _close if @predecessor.closed?
    return '' if @closed

    data = @predecessor.drain_out(n_bytes)
    @cipher.update(data)
  end

  def _close
    @closed = true
    @cipher.final
  end

  def info
    @info.merge(
      @predecessor.info
    )
  end

  def closed?
    @closed
  end
end
