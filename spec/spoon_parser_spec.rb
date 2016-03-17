require 'spec_helper'

describe Spoon::Parser do
  let(:parser) { Spoon::Parser.new }

  context "condition rule" do
    it "should consume 'if (something) do anything'" do
      expect(parser.function).to parse('if (something) then anything')
    end

    it "should consume 'if (something) anything end'" do
      expect(parser.function).to parse('if (something) anything end')
    end

    it "shouldn't consume 'if (something) anything'" do
      expect(parser.function).to_not parse('if (something) anything')
    end
  end

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
