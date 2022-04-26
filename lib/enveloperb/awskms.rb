module Enveloperb
  # An Enveloperb cryptography engine using AWS KMS as a wrapping key provider.
  #
  class AWSKMS
    def self.new(keyid, aws_access_key_id: nil, aws_secret_access_key: nil, aws_session_token: nil, aws_region: nil)
      unless keyid.is_a?(String) && keyid.encoding == Encoding::find("UTF-8") && keyid.valid_encoding?
        raise ArgumentError, "Key ID must be a valid UTF-8 string"
      end

      unless aws_access_key_id.nil? && aws_secret_access_key.nil? && aws_session_token.nil? && aws_region.nil?
        validate_string(aws_access_key_id, :aws_access_key_id)
        validate_string(aws_secret_access_key, :aws_secret_access_key)
        validate_string(aws_region, :aws_region)
        validate_string(aws_session_token, :aws_session_token, allow_nil: true)
      end

      _new(
        keyid,
        {
          access_key_id: aws_access_key_id,
          secret_access_key: aws_secret_access_key,
          session_token: aws_session_token,
          region: aws_region,
        }
      )
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

    class << self
      private

      def validate_string(s, var, allow_nil: false)
        if s.nil? && !allow_nil
          raise ArgumentError, "#{var.inspect} option to Enveloperb::AWSKMS.new() cannot be nil"
        end

        unless s.is_a?(String) && s.encoding == Encoding.find("UTF-8") && s.valid_encoding?
          raise ArgumentError, "#{var.inspect} option passed to Enveloperb::AWSKMS.new() must be a valid UTF-8 string"
        end
      end
    end
  end
end
