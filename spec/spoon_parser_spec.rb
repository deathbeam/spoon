require 'spec_helper'

describe Spoon::Parser do
  let(:parser) { Spoon::Parser.new }

  context "comment parsing" do
    subject { parser.comment }

    it { should parse "# comment" }
    it { should parse "#comment" }
    it { should_not parse "# comment\n expression" }
  end

  context "condition parsing" do
    subject { parser.condition }

    it { should parse "if (something) anything" }
    it { should parse "if (a) b else if (c) d else e" }
    it { should_not parse "if a b c" }
    it { should_not parse "if (something) a b" }
  end

  context "function parsing" do
    subject { parser.function }

    it { should parse "def test() it" }
    it { should parse "def test it" }
    it { should parse "def test(me = 1) it" }
    it { should parse "def test me = 2 it" }
    it { should_not parse "def test() me it" }
    it { should_not parse "def test me it he" }
  end
end
