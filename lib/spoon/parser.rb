require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"

module Spoon
  class Parser < Spoon::Util::IndentParser
    def initialize
      super
      @keywords = [
        "if",
        "else",
        "def",
        "return",
        "and",
        "is",
        "isnt",
        "or",
        "not"
      ]
    end

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      whitespace.maybe >>
      expression.repeat(1) >>
      whitespace.maybe
    }

    # Matches word
    rule(:word) {
      skip_key >>
      match['a-zA-Z\-'].repeat(1).as(:word)
    }

    # Matches strings
    rule(:string) {
      str('"') >> (
        str('\\') >> any |
        str('"').absent? >> any
      ).repeat.as(:string) >> str('"')
    }

    # Matches floats
    rule(:float) {
      integer >> (
        str('.') >> match('[0-9]').repeat(1) |
        str('e') >> match('[0-9]').repeat(1)
      )
    }

    rule(:integer) {
      ((str('+') | str('-')).maybe >> match("[0-9]").repeat(1))
    }

    # Matches number
    rule(:number) {
      (float | integer).as(:number)
    }

    # Matches literals (strings, numbers)
    rule(:literal) {
      (number | string) >> space.maybe
    }

    # Matches value
    rule(:value) {
      (condition |
      closure |
      chain |
      ret |
      word |
      literal) >> space.maybe
    }

    # Matches statement, so everything that is unassignable
    rule(:statement) {
      function >> space.maybe
    }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment) {
      sym("#") >> stop.as(:comment)
    }

    # Matches expression or indented block and skips end of line at end
    rule(:body) {
      (block | expression) >> newline.maybe
    }

    # Matches chain value
    rule(:chain_value) {
      call |
      (word >> space.maybe)
    }

    # Matches chain of expressions
    # example: abc(a).def(b).efg
    rule(:chain) {
      (chain_value >> (op(".") >> chain_value).repeat(1)).as(:chain)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      word >> space.maybe >>
      parens(expression_list.as(:arguments))
    }

    # Matches return statement
    # example: return a, b, c
    rule(:ret) {
      key("return") >> parens(expression_list).maybe.as(:return)
    }

    # Matches indented block and consumes newlines at start and in between
    # but not at end
    rule(:block) {
      newline.maybe >> indent >>
      (expression >> (newline.maybe >> samedent >> expression).repeat).maybe.as(:block) >>
      dedent
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parameter >> (op(",") >> parameter).repeat
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      word.as(:name) >> (op("=") >> expression.as(:value)).maybe
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      expression >> (op(",") >> expression).repeat
    }

    # Matches operator
    rule(:operator) {
      (whitespace.maybe >> match['\+\-\*\/%\^><\|&='].as(:op) >> whitespace.maybe) | op([
        "or",
        "and",
        "is",
        "isnt",
        "<=",
        ">=",
        "!=",
        "==",
        "+=",
        "-=",
        "*=",
        "/=",
        "%=",
        "or=",
        "and="
      ]).as(:op)
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure) {
      (parens(parameter_list.as(:parameters)).maybe >> op("->") >> body.as(:body)).as(:closure)
    }

    # Matches expression
    rule(:expression) {
      statement | (value.as(:left) >> operator >> value.as(:right)) |
      value
    }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (key("def") >> word.as(:name) >> function_body).as(:function)
    }

    # Matches function body
    rule(:function_body) {
      (parens(parameter_list.as(:parameters)).maybe >> body.as(:body)) |
      body.as(:body)
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (key("if") >> parens(expression.as(:body)) >> body.as(:if_true) >> (key("else") >> body.as(:if_false)).maybe).as(:condition)
    }
  end
end
