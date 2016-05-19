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
        :if,
        :else,
        :return,
        :and,
        :is,
        :isnt,
        :or,
        :not,
        :then,
        :in,
        :for,
        :unless,
        :do,
        :while,
        :import,
        :class,
        :as
      ]
    end

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      (
        whitespace.maybe >>
        import.repeat >>
        (classdef | expression).repeat >>
        whitespace.maybe
      ).as(:root)
    }

    # Matches expression or indented block and skips end of line at end
    rule(:body) {
      (space.maybe >> DO()).maybe >> (
        block |
        expression
      )
    }

    # Matches indented block
    rule(:block) {
      endline.maybe >>
      indent >>
      repeat(expression, samedent).as(:block) >>
      dedent
    }

    rule(:import) {
      space.maybe >>
      IMPORT() >>
      space.maybe >>
      repeat((ident | type | STAR().as(:ident)), DOT()).as(:import) >>
      endline.maybe
    }

    # Matches expression
    # TODO: Add decorators (postfix if, unless, for and while)
    rule(:expression) {
      space.maybe >>
      (unary_operation | operation | value) >>
      endline.maybe
    }

    # Matches operation
    rule(:operation) {
      infix_expression(
        unary_operation | value | parens(operation, true),
        [DOT(), 14, :left],
        [RANGE(), 13, :left],
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
        [CASSIGN(), 2, :right],
        [ASSIGN(), 1, :right]
      )
    }

    # Matches unary operation
    # example: !foo
    # TODO: Enable spaces between operator and value
    rule(:unary_operation) {
      ((INCREMENT() | UNARY()).as(:o) >> value.as(:r)) |
      (value.as(:l) >> INCREMENT().as(:o))
    }

    # Matches object construction
    # example: new Foo!
    rule(:construct) {
      (
        type.as(:name) >>
        space.maybe >> (EXCLAMATION() |  expression_list.as(:args))
      ).as(:construct)
    }

    # Matches value
    rule(:value) {
      annotation |
      closure |
      condition |
      condition_reverse |
      for_loop |
      while_loop |
      construct |
      array_access |
      call |
      import |
      ret |
      hash |
      array |
      literal |
      self_call |
      this_call |
      typed |
      ident |
      type
    }

    # Matches annotation
    rule(:annotation) {
      DOUBLE_DOT() >> (unary_operation | operation | value).as(:annotation) >> endline
    }

    rule(:self_call) {
      str('@@') >> value.as(:self)
    }

    rule(:this_call) {
      str('@') >> value.as(:this)
    }

    rule(:field) {
      (ident | self_call | this_call | string).as(:l) >>
      trim(DOUBLE_DOT()).as(:o) >>
      expression.as(:r)
    }

    rule(:classdef) {
      CLASS() >> space.maybe >> (type.as(:name) >> body.as(:body)).as(:class)
    }

    # Matches array access
    rule(:array_access) {
      (ident.as(:l) >> trim(str('[')) >>
      expression.as(:r) >>
      whitespace.maybe >> str(']')).as(:access)
    }

    rule(:array) {
      str('[') >> whitespace.maybe >>
      repeat(expression, COMMA()).as(:array) >>
      whitespace.maybe >> str(']')
    }

    rule(:hash) {
      str('[') >> whitespace.maybe >>
      repeat(field, COMMA()).as(:hash) >>
      whitespace.maybe >> str(']')
    }

    # Matches typed word
    rule(:typed) {
      ident.as(:l) >> trim(AS().as(:o)) >> type.as(:r)
    }

    # Matches word
    rule(:ident) {
      skip_key >>
      (
        match['a-z'] >>
        match['a-zA-Z0-9\-'].repeat
      ).as(:ident)
    }

    # Matches type
    rule(:type) {
      skip_key >>
      (
        match['A-Z'] >>
        match['a-zA-Z0-9\-'].repeat
      ).as(:type)
    }

    # Matches true false
    rule(:boolean) {
      (str(:true) | str(:false)).as(:boolean)
    }

    # Matches strings
    rule(:string) {
      str('"') >>
      (text.as(:text) | interpolation).repeat.as(:string) >>
      str('"')
    }

    # Matches text inside string
    rule(:text) {
      (
        interpolation.absent? >>
        (str('\\') >> any | str('"').absent? >> any)
      ).repeat(1)
    }

    # Matches interpolation inside string
    rule(:interpolation) {
      (str('\\').absent? >> str('#{') >> expression >> str('}')) |
      str('\\').absent? >> str('#') >> expression
    }

    # Matches numbers
    rule(:number) {
      (
        match('[0-9]').repeat(1) >>
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
      expression.maybe.as(:return)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      (
        (ident | self_call | this_call).as(:name) >>
        space.maybe >> (EXCLAMATION() | expression_list.as(:args))
      ).as(:call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      ident.as(:name) >> (ASSIGN() >> expression.as(:value)).maybe
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parens(repeat(parameter.as(:param), COMMA()))
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      parens(repeat(expression, COMMA()))
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

    # Matches for loop
    rule(:for_loop) {
      (
        FOR() >>
        space.maybe >>
        parens(ident.as(:l) >> trim(IN()).as(:o) >> expression.as(:r)).as(:condition) >>
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
        condition_body
      ).as(:if)
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition_reverse) {
      (
        UNLESS() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        condition_body
      ).as(:unless)
    }

    # Matches condition body
    rule(:condition_body) {
      body.as(:true) >>
      (
        space.maybe >>
        ELSE() >>
        body.as(:false)
      ).maybe
    }
  end
end
