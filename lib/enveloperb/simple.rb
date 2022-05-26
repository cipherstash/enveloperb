module Enveloperb
  # An Enveloperb cryptography engine using an unprotected string as the wrapping key.
  #
  class Simple
    def self.new(k)
      unless k.is_a?(String) && k.encoding == Encoding::BINARY
        raise ArgumentError, "Key must be a binary string"
      end

      unless k.bytesize == 16
        raise ArgumentError, "Key must be 16 bytes"
      end

      _new(k)
    end

    def encrypt(s)
      unless s.is_a?(String)
        raise ArgumentError, "Can only encrypt strings"
      end

      _encrypt(s)
    end

    def decrypt(er)
      unless er.is_a?(EncryptedRecord)
        raise ArgumentError, "Can only decrypt EncryptedRecord objects; you can make one from a string with EncryptedRecord.new"
      end

      _decrypt(er)
    end
  end
end
