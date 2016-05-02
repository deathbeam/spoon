require 'spec_helper'

describe Spoon::Parser do
  let(:parser) { Spoon::Parser.new }

  context "block" do
    subject { parser.block }

    it { should parse "\n print foo\n return bar\n" }
    it { should_not parse "\n print foo\n return bar" }
    it { should_not parse "\n  print foo\n  return bar\n " }
  end

  context "call" do
    subject { parser.call }

    it { should parse "foo bar" }
    it { should parse "foo(bar)" }
    it { should parse "foo bar, baz" }
    it { should parse "foo(bar, baz)" }
  end

  context "closure" do
    subject { parser.closure }

    it { should parse "-> foo" }
    it { should parse "() -> foo" }
    it { should parse "foo -> bar" }
    it { should parse "foo, bar -> baz" }
    it { should parse "(foo, bar) -> baz" }
  end

  context "comment" do
    subject { parser.comment }

    it { should parse "# foo" }
    it { should parse "#foo" }
    it { should_not parse "# foo\n bar" }
  end

  context "condition" do
    subject { parser.condition }

    it { should parse "if (foo) bar" }
    it { should parse "if foo do bar" }
    it { should parse "if (foo) bar else if (baz) foo else bar" }
    it { should_not parse "if foo bar" }
  end

  context "reverse condition" do
    subject { parser.condition_reverse }

    it { should parse "unless (foo) bar" }
    it { should parse "unless foo do bar" }
    it { should parse "unless (foo) bar else if (baz) foo else bar" }
    it { should_not parse "unless foo bar" }
  end

  context "expression" do
    subject { parser.expression }
    it { should parse "foo and bar" }
    it { should parse "foo + bar" }
    it { should parse "foo * bar" }
    it { should parse "++foo" }
    it { should parse "foo++" }
    it { should parse "a = b * c * d * e" }
    it { should parse "foo.bar.(baz())" }
    it { should_not parse "foo ** bar" }
  end

  context "for" do
    subject { parser.for_loop }

    it { should parse "for (foo in bar) baz" }
    it { should parse "for foo in bar do baz" }
  end

  context "function" do
    subject { parser.function }

    it { should parse "function foo bar" }
    it { should parse "function foo() bar" }
    it { should parse "function foo bar = 1 baz" }
    it { should parse "function foo(bar = 1) baz" }
  end

  context "number" do
    subject { parser.number }

    it { should parse "10" }
    it { should parse "0" }
    it { should parse "1.0" }
    it { should parse "0.0" }
    it { should parse "1e10" }
    it { should_not parse "a2" }
  end

  context "root" do
    subject { parser.root }

    it { should parse "# foo\n    print bar\n # baz " }
  end

  context "while" do
    subject { parser.while_loop }

    it { should parse "while (foo) baz" }
    it { should parse "while foo do baz" }
  end

  context "word" do
    subject { parser.word }

    it { should parse "foo" }
    it { should parse "Foo" }
    it { should parse "foo-bar" }
    it { should_not parse "-foo" }
    it { should_not parse "foo2" }
    it { should_not parse "foo?" }
    it { should_not parse "foo_bar" }
  end
end
