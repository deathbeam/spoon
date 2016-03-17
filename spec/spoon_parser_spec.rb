require 'spec_helper'

describe Spoon::Parser do
  let(:parser) { Spoon::Parser.new }

  context "function rule" do
    it "should consume 'def test do it'" do
      expect(parser.function).to parse('def test do it')
    end

    it "should consume 'def test() it end'" do
      expect(parser.function).to parse('def test() it end')
    end

    it "should consume 'def test(me) it end'" do
      expect(parser.function).to parse('def test(me) it end')
    end

    it "shouldn't consume 'def test() it'" do
      expect(parser.function).to_not parse('def test() it')
    end
  end
end
