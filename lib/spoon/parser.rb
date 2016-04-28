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
      (statement | operation) >>
      endline.maybe
    }

    # Matches block starting with do keyword
    rule(:block) {
      space.maybe >>
      key("do") >>
      body.as(:Block)
    }

    # Matches operation
    rule(:operation) {
       unary_operation | infix_expression(
        parens(value) | parens(operation, true),
        [trim(str(".")), 2, :left],
        [trim(match['\*/%']), 5, :left],
        [trim(match['\+\-']), 6, :left],
        [trim(str("<<") | str(">>")), 7, :left],
        [trim(match['<>'] |str("<=") | str(">=")), 8, :left],
        [trim(str("==") | str("!=") | key("is") | key("isnt")), 9, :left],
        [trim(str("&")), 10, :left],
        [trim(str("^")), 11, :left],
        [trim(str("|")), 12, :left],
        [trim(str("&&") | key("and")), 13, :left],
        [trim(str("||") | key("or")), 14, :left],
        [trim(str("+=") | str("-=") | str("*=") | str("/=") |
              str("%=") | str("<<=") | str(">>=") | str("&=")|
              str("^=") | str("|=") | str("=") | key("in")), 15, :right]
      )
    }

    # Matches unary operation
    # example: !foo
    rule(:unary_operation) {
      (trim(str("++") | str("--") | key("not") | match['\+\-!']).as(:Op) >> value.as(:Right)) |
      (value.as(:Left) >> trim(str("++") | str("--")).as(:Op))
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
      str("#") >>
      stop >>
      newline.maybe
    }

    # Matches return statement
    # example: return a, b, c
    rule(:ret) {
      key("return") >>
      space.maybe >>
      expression_list.maybe.as(:Return)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      (
        name >>
        (
          str("!") |
          (
            space.maybe >>
            expression_list
          )
        )
      ).as(:Call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      name.as(:Name) >>
      (
        trim(str("=")) >>
        expression
      ).maybe
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parens(repeat(parameter.as(:Param), trim(str(","))))
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      parens(repeat(expression.as(:Arg), trim(str(","))))
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure) {
      (
        parameter_list.maybe >>
        whitespace.maybe >>
        str("->") >>
        body
      ).as(:Closure)
    }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (
        key("function") >>
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
        key("if") >>
        space.maybe >>
        parens(expression) >>
        space.maybe >>
        key("then").maybe >>
        body.as(:True) >>
        (
          space.maybe >>
          key("else") >>
          body.as(:False)
        ).maybe
      ).as(:If)
    }
  end
end
