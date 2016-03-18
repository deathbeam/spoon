require 'spec_helper'

describe Spoon::Parser do
  let(:parser) { Spoon::Parser.new }

  context "comment rule" do
    it "should consume '# comment'" do
      expect(parser.comment).to parse('# comment')
    end

    it "should consume '#comment'" do
      expect(parser.comment).to parse('#comment')
    end

    it "shouldn't consume '# comment\\n expression'" do
      expect(parser.comment).to parse('# comment\n expression')
    end
  end

  context "condition rule" do
    it "should consume 'if (something) anything'" do
      expect(parser.condition).to parse('if (something) anything')
    end

    it "should consume 'if (a) b else if (c) d else e'" do
      expect(parser.condition).to parse('if (a) b else if (c) d else e')
    end

    it "shouldn't consume 'if something anything'" do
      expect(parser.condition).to_not parse('if something anything')
    end

    it "shouldn't consume 'if (something) a b'" do
      expect(parser.condition).to_not parse('if (something) a b')
    end
  end

  context "function rule" do
    it "should consume 'def test it'" do
      expect(parser.function).to parse('def test it')
    end

    it "should consume 'def test() it'" do
      expect(parser.function).to parse('def test() it')
    end

    it "should consume 'def test(me) it'" do
      expect(parser.function).to parse('def test(me) it')
    end

    it "shouldn't consume 'def test() me it'" do
      expect(parser.function).to_not parse('def test() me it')
    end

    it "shouldn't consume 'def test me it'" do
      expect(parser.function).to_not parse('def test me it')
    end
  end
end
