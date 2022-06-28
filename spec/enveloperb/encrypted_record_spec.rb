require_relative '../spec_helper'
require 'enveloperb'

describe Enveloperb::EncryptedRecord do
  let(:record) { described_class.new(input) }
  let(:valid_input) do
    [
      (
        "a46d656e63727970 7465645f6b657998 20189d18c618ae18 7f187d18f9187f18" +
        "b518a7131859184f 18ce18c4186418cf 1118d918d718b818 dc18e2185318e718" +
        "c5186518e518b718 b518c8181d18916a 6369706865727465 787498241837185d" +
        "1851187c1866186c 184018d518ac18b1 185418c0184a0d18 2909186b18541847" +
        "183618a418501843 1847181a18f3189e 186a18e218231831 185d185216187418" +
        "ac656e6f6e63658c 184c182818c818ff 0b0e1866182a18e5 1861189618e6666b" +
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
