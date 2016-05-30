require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"
require "spoon/util/parser_literals"

module Spoon
  class Parser < Spoon::Util::IndentParser
    def parse_with_debug(text)
      begin
        parse(text, reporter: Parslet::ErrorReporter::Deepest.new)
      rescue Parslet::ParseFailed => error
        puts error.cause.ascii_tree
        false
      end
    end

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      (
        whitespace.maybe >>
        (statement | expression).repeat >>
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

    # Matches statements
    # TODO: Add interfaces, abstracts and enums
    rule(:statement) {
      space.maybe >> (import | classdef)
    }

    # Matches expression
    # TODO: Add decorators (postfix if, unless, for and while)
    rule(:expression) {
      space.maybe >>
      (unary_operation | operation | value) >>
      endline.maybe
    }

    # Matches value
    # TODO: Add ternary or existential operator
    # TODO: Add switch-when, try-catch, break and continue
    rule(:value) {
      annotation |
      closure |
      fat_closure |
      condition_def |
      condition |
      condition_reverse |
      for_loop |
      while_loop |
      until_loop |
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

    # Matches operation
    # example: a * b
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

    # Matches import
    # example: import foo.bar.Baz.*
    # TODO: Implement import syntax from this issue: https://github.com/nondev/spoon/issues/26
    rule(:import) {
      IMPORT() >>
      space.maybe >>
      repeat((ident | type | STAR().as(:ident)), DOT()).as(:import) >>
      endline.maybe
    }

    # Matches object construction
    # example: Foo!
    rule(:construct) {
      (
        type.as(:name) >>
        space.maybe >> (EXCLAMATION() |  expression_list.as(:args))
      ).as(:construct)
    }

    # Matches annotation
    # example: \annotation
    rule(:annotation) {
      str('\\') >> (unary_operation | operation | value).as(:annotation) >> endline
    }

    # Matches self call
    # example: @@foo
    # TODO: Add also "self." syntax?
    rule(:self_call) {
      str('@@') >> value.as(:self)
    }

    # Matches this call
    # example: @foo
    # TODO: Add also "this." syntax?
    rule(:this_call) {
      str('@') >> value.as(:this)
    }

    # Matches hash field
    # example: a : b
    rule(:field) {
      (ident | self_call | this_call | string).as(:l) >>
      DOUBLE_DOT().as(:o) >>
      expression.as(:r)
    }

    # Matches class definition
    # example: class Foo < Bar do @baz = "Baz"
    # TODO: Add also "implements", to implement interfaces
    rule(:classdef) {
      CLASS() >> space.maybe >>
      (
        type.as(:name) >>
        (trim(EXTENDS()) >> type.as(:extends)).maybe >>
        body.as(:body)
      ).as(:class)
    }

    # Matches array access
    # example: foo[bar]
    # TODO: Implement something similar for generics
    rule(:array_access) {
      (ident.as(:l) >> trim(str('[')) >>
      expression.as(:r) >>
      whitespace.maybe >> str(']')).as(:access)
    }

    # Matches array
    # example: [ foo, bar ]
    rule(:array) {
      str('[') >> whitespace.maybe >>
      repeat(expression, COMMA()).as(:array) >>
      whitespace.maybe >> str(']')
    }

    # Matches hash
    # example: { foo: bar, baz: foo }
    rule(:hash) {
      str('{') >> whitespace.maybe >>
      repeat(field, COMMA()).as(:hash) >>
      whitespace.maybe >> str('}')
    }

    # Matches typed word
    # example: foo : Bar
    rule(:typed) {
      (ident.as(:value) >> DOUBLE_DOT() >> type).as(:typed)
    }

    # Matches word
    # example: to-string
    rule(:ident) {
      skip_key >>
      (
        match['a-z'] >>
        match['a-zA-Z0-9\-'].repeat
      ).as(:ident)
    }

    # Matches type
    # example: MyType
    rule(:type) {
      skip_key >>
      (
        (
          (match['a-z'] >> match['a-zA-Z0-9\-'].repeat >> DOT()).repeat >>
          match['A-Z'] >>
          match['a-zA-Z0-9\-'].repeat
        ).as(:ident).as(:type) >>
        (
          trim(str("<")) >>
          repeat(type, COMMA()).as(:generic) >>
          whitespace.maybe >> str(">")
        ).maybe
      ).as(:type)
    }

    # Matches true/false
    rule(:boolean) {
      (key(:true) | key(:false)).as(:boolean)
    }

    # Matches strings
    # TODO: Add support for single quotes
    rule(:string) {
      str('"') >>
      (text.as(:string) | interpolation).repeat.maybe.as(:string) >>
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
    # example: #{my-expression}
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
          str('e') >> match('[0-9]').repeat(1) |
          str('x') >> match('[a-zA-Z0-9]').repeat(1)
        ).maybe
      ).as(:number)
    }

    # Matches literals (strings, numbers)
    # TODO: Add "null" and "void" literal
    rule(:literal) {
      number | string | boolean
    }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    # TODO: Add support for block comments
    rule(:comment) {
      HASH() >>
      stop
    }

    # Matches return statement
    # example: return foo
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
        space.maybe >> (EXCLAMATION() >> space.maybe >> str("=").absent? | expression_list.as(:args))
      ).as(:call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      ident.as(:name) >>
      (DOUBLE_DOT() >> type).maybe >>
      (ASSIGN() >> expression.as(:value)).maybe
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
        (DOUBLE_DOT() >> type).maybe >>
        whitespace.maybe >>
        ARROW() >>
        body.as(:body)
      ).as(:closure)
    }

    # Matches fat closure (no implicit return)
    # example: (a) => b
    rule(:fat_closure) {
      (
        parameter_list.as(:params).maybe >>
        (DOUBLE_DOT() >> type).maybe >>
        whitespace.maybe >>
        FAT_ARROW() >>
        body.as(:body)
      ).as(:fat_closure)
    }

    # Matches for loop
    # example: for (foo in bar) baz
    rule(:for_loop) {
      (
        FOR() >>
        space.maybe >>
        parens(
          ((ident.as(:l) >> COMMA().as(:o) >> ident.as(:r)) | ident).as(:l) >>
          trim(IN()).as(:o) >> expression.as(:r)
        ).as(:condition) >>
        body.as(:body)
      ).as(:for)
    }

    # Matches while loop
    # example: while (foo) bar
    rule(:while_loop) {
      (
        WHILE() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        body.as(:body)
      ).as(:while)
    }

    # Matches while loop
    # example: while (foo) bar
    rule(:until_loop) {
      (
        UNTIL() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        body.as(:body)
      ).as(:until)
    }

    # Matches compiler-scoped condition
    # example: ifdef (a) b else if(c) d else e
    rule(:condition_def) {
      (
        IFDEF() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        condition_body
      ).as(:ifdef)
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

    # Matches unless-else unless-else in recursive structure
    # example: unless (a) b else c
    rule(:condition_reverse) {
      (
        UNLESS() >>
        space.maybe >>
        parens(expression).as(:condition) >>
        condition_body
      ).as(:unless)
    }

    # Matches condition body
    # example: foo else bar
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
