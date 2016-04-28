require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"
require "spoon/util/parser_literals"

module Spoon
  class Parser < Spoon::Util::IndentParser
    # Initialize the keyword map
    def initialize
      super
      @keywords = [
        "if",
        "else",
        "function",
        "return",
        "and",
        "is",
        "isnt",
        "or",
        "not",
        "then",
        "in"
      ]
    end

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      (
        whitespace.maybe >>
        expression.repeat(1) >>
        whitespace.maybe
      ).as(:Block)
    }

    # Matches expression or indented block and skips end of line at end
    rule(:body) {
      (
        block_expression |
        expression
      ).as(:Block)
    }

    # Matches indented block
    rule(:block_expression) {
      endline.maybe >>
      indent >>
      repeat(expression, samedent) >>
      dedent
    }

    # Matches expression
    rule(:expression) {
      space.maybe >>
      (statement | operation | value) >>
      endline.maybe
    }

    # Matches block starting with do keyword
    rule(:block) {
      space.maybe >>
      DO() >>
      body.as(:Block)
    }

    # Matches operation
    rule(:operation) {
       unary_operation.as(:Op) | infix_expression(
        unary_operation.as(:Op) | parens(value) | parens(operation, true),
        [DOT(), 13, :left],
        [MUL(), 12, :left],
        [ADD(), 11, :left],
        [SHIFT(), 10, :left],
        [COMPARE(), 9, :left],
        [EQ(), 8, :left],
        [BAND(), 7, :left],
        [BXOR(), 6, :left],
        [BOR(), 5, :left],
        [AND(), 4, :left],
        [OR(), 3, :left],
        [ASSIGN(), 2, :right],
        [CASSIGN(), 1, :right]
      )
    }

    # Matches unary operation
    # example: !foo
    rule(:unary_operation) {
      (((INCREMENT() | UNARY()) >> space.maybe).as(:Name) >> value.as(:Right)) |
      (value.as(:Left) >> space.maybe >> INCREMENT().as(:Name))
    }

    # Matches value
    rule(:value) {
      condition |
      closure |
      block |
      call |
      ret |
      name.as(:Value) |
      literal
    }

    # Matches statement, so everything that is unassignable
    rule(:statement) {
      function
    }

    # Matches word
    rule(:name) {
      skip_key >>
      match['a-zA-Z'] >>
      match['a-zA-Z\-'].repeat
    }

    # Matches strings
    rule(:string) {
      str('"') >>
      (
        str('\\') >> any |
        str('"').absent? >> any
      ).repeat >>
      str('"')
    }

    # Matches numbers
    rule(:number) {
      match("[0-9]").repeat(1) >>
      (
        str('.') >> match('[0-9]').repeat(1) |
        str('e') >> match('[0-9]').repeat(1)
      ).maybe
    }

    # Matches literals (strings, numbers)
    rule(:literal) {
      (number | string).as(:Value)
    }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment) {
      HASH() >>
      stop >>
      newline.maybe
    }

    # Matches return statement
    # example: return a, b, c
    rule(:ret) {
      RETURN() >>
      space.maybe >>
      expression_list.maybe.as(:Return)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      (name >> space.maybe >> (EXCLAMATION() |  expression_list)).as(:Call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      name.as(:Name) >> (ASSIGN() >> expression).maybe
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parens(repeat(parameter.as(:Param), COMMA()))
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      parens(repeat(expression.as(:Arg), COMMA()))
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure) {
      (
        parameter_list.maybe >>
        whitespace.maybe >>
        ARROW() >>
        body
      ).as(:Closure)
    }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (
        FUNCTION() >>
        space.maybe >>
        name.as(:Name) >>
        function_body
      ).as(:Function)
    }

    # Matches function body
    rule(:function_body) {
      (
        space.maybe >>
        parameter_list.maybe >>
        body
      ) | body
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (
        IF() >>
        space.maybe >>
        parens(expression) >>
        space.maybe >>
        THEN().maybe >>
        body.as(:True) >>
        (
          space.maybe >>
          ELSE() >>
          body.as(:False)
        ).maybe
      ).as(:If)
    }
  end
end
