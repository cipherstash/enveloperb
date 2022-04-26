require_relative '../spec_helper'
require 'enveloperb'

require "securerandom"

describe Enveloperb::AWSKMS do
  let(:key_arn) { ENV["ENVELOPERB_TEST_KMS_KEY_ARN"] }
  let(:engine) { described_class.new(key_arn) }


  around(:each) do |example|
    if ENV["ENVELOPERB_TEST_KMS_KEY_ARN"] && ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"]
      example.run
    else
      pending
      fail "No KMS key ARN and access credentials; can't test KMS provider"
    end
  end

  describe ".new" do
    context "with just a key ARN" do
      it "works" do
        expect { engine }.to_not raise_error
      end

      it "returns an AWSKMS engine" do
        expect(engine).to be_a(Enveloperb::AWSKMS)
      end
    end

    context "with explicit AWS credentials" do
      let(:engine) do
        described_class.new(
          key_arn,
          aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"],
          aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
          aws_region: ENV["AWS_REGION"],
          aws_session_token: ENV["AWS_SESSION_TOKEN"]
        )
      end

      around(:each) do |example|
        with_env(
          "AWS_ACCESS_KEY_ID" => nil,
          "AWS_SECRET_ACCESS_KEY" => nil,
          "AWS_REGION" => nil,
          "AWS_SESSION_TOKEN" => nil
        ) do
          example.run
        end
      end

      it "works" do
        expect { engine }.to_not raise_error
      end

      it "returns an AWSKMS engine" do
        expect(engine).to be_a(Enveloperb::AWSKMS)
      end
    end

    {
      "key ARN that isn't a string"             => Object.new,
      "key ARN that isn't a valid UTF-8 string" => "\xe4",
      "key ARN that is a binary string"         => "ohai!".force_encoding("BINARY"),
    }.each do |desc, val|
      context "with a #{desc}" do
        it "raises ArgumentError" do
          expect { described_class.new(val) }.to raise_error(ArgumentError)
        end
      end
    end

    {
      "session token that isn't a string"             => Object.new,
      "session token that isn't a valid UTF-8 string" => "\xe4",
      "session token that is a binary string"         => "ohai!".force_encoding("BINARY"),
    }.each do |desc, val|
      context "with a #{desc}" do
        it "raises ArgumentError" do
          expect { described_class.new("arn", aws_access_key_id: "x", aws_secret_access_key: "x", aws_region: "x", aws_session_token: val) }.to raise_error(ArgumentError)
        end
      end
    end

    %i{aws_access_key_id aws_secret_access_key aws_region}.each do |opt|
      {
        "is nil"                     => nil,
        "isn't a string"             => Object.new,
        "isn't a valid UTF-8 string" => "\xe4",
        "is a binary string"         => "ohai!".force_encoding("BINARY"),
      }.each do |desc, val|
        context "with #{opt.inspect} that #{desc}" do
          it "raises ArgumentError" do
            expect { described_class.new("arn", { aws_access_key_id: "x", aws_secret_access_key: "x", aws_region: "x" }.merge({ opt => val })) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end

  describe "#encrypt" do
    it "successfully encrypts" do
      expect { engine.encrypt("s3kr1t") }.to_not raise_error
    end

    it "produces an EncryptedRecord" do
      expect(engine.encrypt("s00p3rs3kr1t")).to be_a(Enveloperb::EncryptedRecord)
    end

    it "only accepts strings" do
      expect { engine.encrypt(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe "#decrypt" do
    let(:ct) { engine.encrypt("s3kr1t") }

    it "successfully decrypts an encrypted record" do
      expect { engine.decrypt(ct) }.to_not raise_error
    end

    it "produces a string" do
      expect(engine.decrypt(ct)).to be_a(String)
    end

    it "produces a binary string" do
      expect(engine.decrypt(ct).encoding).to eq(Encoding::BINARY)
    end

    it "produces the *correct* binary string" do
      expect(engine.decrypt(ct)).to eq("s3kr1t")
    end

    it "dislikes decrypting other things" do
      expect { engine.decrypt("s3kr1t") }.to raise_error(ArgumentError)
    end
  end
end
