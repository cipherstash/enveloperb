require_relative '../spec_helper'
require 'enveloperb'

require "securerandom"

describe Enveloperb::Simple do
  let(:engine) { described_class.new(key) }

  describe ".new" do
    context "with a valid key" do
      let(:key) { SecureRandom.bytes(16) }

      it "works" do
        expect { engine }.to_not raise_error
      end

      it "returns a Simple engine" do
        expect(engine).to be_a(Enveloperb::Simple)
      end
    end

    {
      "short key"        => SecureRandom.bytes(15),
      "long key"         => SecureRandom.bytes(17),
      "a non-binary key" => "Ohai!",
      "a non-string key" => Object.new,
    }.each do |desc, obj|
      context "with #{desc}" do
        let(:key) { obj }

        it "raises ArgumentError" do
          expect { engine }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#encrypt" do
    let(:key) { SecureRandom.bytes(16) }

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
    let(:key) { SecureRandom.bytes(16) }
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
