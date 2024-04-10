# frozen_string_literal: true

require 'openssl'
require 'base64'
require_relative '../interface'

# The tunnel that performs AES decryption on the data.
class AESDecryptionTunnel < Tunnel
  def initialize(predecessor, password)
    super()
    @predecessor = predecessor
    @closed = false
    _init_cipher(password)
  end

  def _init_cipher(password)
    @cipher = OpenSSL::Cipher.new('aes-128-ctr').decrypt
    iv = Base64.strict_decode64(info['cipher_iv'])
    salt = Base64.strict_decode64(info['key_salt'])
    @cipher.key = OpenSSL::KDF.pbkdf2_hmac(
      password,
      salt: salt, iterations: 2 << 16,
      length: @cipher.key_len, hash: 'SHA256'
    )
    @cipher.iv = iv
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
    @predecessor.info.dup
  end

  def closed?
    @closed
  end
end
