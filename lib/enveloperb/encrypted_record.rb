module Enveloperb
  # An envelope encrypted record.
  class EncryptedRecord
    # Create an encrypted record from a serialized form.
    #
    # Encrypted records can be serialized (using #to_s), and then deserialized by passing them into this constructor.
    #
    # @param s [String] the serialized encrypted record.
    #   This must be a `BINARY` encoded string.
    #
    # @raises [ArgumentError] if something other than a binary string is provided, or if the string passed as the serialized encrypted record is not valid.
    #
    def self.new(s)
      unless s.is_a?(String) && s.encoding == Encoding::BINARY
        raise ArgumentError, "Serialized encrypted record must be a binary string"
      end

      _new(s)
    end

    # Serialize an encrypted record into a string.
    #
    # @return [String]
    #
    # @raise [RuntimeError] if something goes spectacularly wrong with the serialization process.
    #
    def to_s
      _serialize
    end
  end
end
