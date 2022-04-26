require_relative '../spec_helper'
require 'enveloperb'

describe Enveloperb::EncryptedRecord do
  let(:record) { described_class.new(input) }
  let(:valid_input) do
    [
      (
        "a46a636970686572 7465787498241837 185d1851187c1866 186c184018d518ac" +
        "18b1185418c0184a 0d182909186b1854 1847183618a41850 18431847181a18f3" +
        "189e186a18e21823 1831185d18521618 7418ac6d656e6372 79707465645f6b65" +
        "799820189d18c618 ae187f187d18f918 7f18b518a7131859 184f18ce18c41864" +
        "18cf1118d918d718 b818dc18e2185318 e718c5186518e518 b718b518c8181d18" +
        "91656e6f6e63658c 184c182818c818ff 0b0e1866182a18e5 1861189618e6666b" +
        "65795f6964697369 6d706c656b6579"
      ).gsub(/[^0-9a-f]+/, '')
    ].pack("H*")
  end

  describe ".new" do
    context "with valid input" do
      let(:input) { valid_input }

      it "works" do
        expect { record }.to_not raise_error
      end

      it "returns an EncryptedRecord object" do
        expect(record).to be_a(Enveloperb::EncryptedRecord)
      end
    end

    {
      "invalid input" => "Ohai!".force_encoding("BINARY"),
      "a non-binary string" => "Ohai!",
      "a non-string"        => Object.new,
    }.each do |desc, obj|
      context "with #{desc}" do
        let(:input) { obj }

        it "raises ArgumentError" do
          expect { record }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#to_s" do
    let(:input) { valid_input }

    it "works" do
      expect { record.to_s }.to_not raise_error
    end

    it "returns a string" do
      expect(record.to_s).to be_a(String)
    end

    it "returns a *binary* string" do
      expect(record.to_s.encoding).to eq(Encoding::BINARY)
    end

    it "returns the same string" do
      expect(record.to_s).to eq(valid_input)
    end
  end
end
