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
        "in",
        "for",
        "while"
      ]
    end

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      (
        whitespace.maybe >>
        expression.repeat(1) >>
        whitespace.maybe
      ).as(:root)
    }

    # Matches expression or indented block and skips end of line at end
    rule(:body) {
      (
        block_expression |
        expression
      )
    }

    # Matches indented block
    rule(:block_expression) {
      endline.maybe >>
      indent >>
      repeat(expression, samedent).as(:block) >>
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
      body.as(:block)
    }

    # Matches operation
    rule(:operation) {
       unary_operation | infix_expression(
        unary_operation | parens(value) | parens(operation, true),
        [DOT(), 12, :left],
        [MUL(), 11, :left],
        [ADD(), 10, :left],
        [SHIFT(), 9, :left],
        [COMPARE(), 8, :left],
        [EQ(), 7, :left],
        [BAND(), 6, :left],
        [BXOR(), 5, :left],
        [BOR(), 4, :left],
        [AND(), 3, :left],
        [OR(), 2, :left],
        [ASSIGN(), 1, :right],
        [CASSIGN(), 1, :right]
      )
    }

    # Matches unary operation
    # example: !foo
    rule(:unary_operation) {
      ((INCREMENT() | UNARY()).as(:op) >> value.as(:right)) |
      (value.as(:left) >> INCREMENT().as(:op))
    }

    # Matches value
    rule(:value) {
      condition |
      for_loop |
      while_loop |
      closure |
      block |
      call |
      ret |
      literal |
      word.as(:identifier)
    }

    # Matches statement, so everything that is unassignable
    rule(:statement) {
      function
    }

    # Matches word
    rule(:word) {
      skip_key >>
      (
        match['a-zA-Z'] >>
        match['a-zA-Z\-'].repeat
      )
    }

    # Matches true false
    rule(:boolean) {
      (str("true") | str("false")).as(:boolean)
    }

    # Matches strings
    rule(:string) {
      str('"') >>
      (
        str('\\') >> any |
        str('"').absent? >> any
      ).repeat.as(:string) >>
      str('"')
    }

    # Matches numbers
    rule(:number) {
      (
        match("[0-9]").repeat(1) >>
        (
          str('.') >> match('[0-9]').repeat(1) |
          str('e') >> match('[0-9]').repeat(1)
        ).maybe
      ).as(:number)
    }

    # Matches literals (strings, numbers)
    rule(:literal) {
      number | string | boolean
    }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment) {
      HASH() >>
      stop
    }

    # Matches return statement
    # example: return a, b, c
    rule(:ret) {
      RETURN() >>
      space.maybe >>
      argument_list.maybe.as(:return)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      (word.as(:name) >> space.maybe >> (EXCLAMATION() |  argument_list.as(:args))).as(:call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      word.as(:name) >> (ASSIGN() >> expression.as(:value)).maybe
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parens(repeat(parameter.as(:param), COMMA()))
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:argument_list) {
      parens(repeat(expression.as(:arg), COMMA()))
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure) {
      (
        parameter_list.as(:params).maybe >>
        whitespace.maybe >>
        ARROW() >>
        body.as(:body)
      ).as(:closure)
    }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (
        FUNCTION() >>
        space.maybe >>
        word.as(:name) >>
        function_body
      ).as(:function)
    }

    # Matches function body
    rule(:function_body) {
      (
        space.maybe >>
        parameter_list.as(:params).maybe >>
        body.as(:body)
      ) | body.as(:body)
    }

    # Matches for loop
    rule(:for_loop) {
      (
        FOR() >>
        space.maybe >>
        parens(word.as(:identifier).as(:left) >> trim(IN()).as(:op) >> expression.as(:right)).as(:condition) >>
        body.as(:body)
      ).as(:for)
    }

    # Matches while loop
    rule(:while_loop) {
      (
        WHILE() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        body.as(:body)
      ).as(:while)
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (
        IF() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        space.maybe >>
        THEN().maybe >>
        body.as(:true) >>
        (
          space.maybe >>
          ELSE() >>
          body.as(:false)
        ).maybe
      ).as(:if)
    }
  end
end
