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
        "in",
        "of"
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
      block_expression |
      expression
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
      body.as(:block)
    }

    # Matches operation
    rule(:operation) {
       unary_operation | infix_expression(
        parens(value) | parens(expression, true),
        [trim(str(".")), 2, :left],
        [trim(match['\*/%']), 5, :left],
        [trim(match['\+\-']), 6, :left],
        [trim(str("<<") | str(">>")), 7, :left],
        [trim(match['<>'] |str("<=") | str(">=")), 8, :left],
        [trim(str("==") | str("!=")), 9, :left],
        [trim(str("&")), 10, :left],
        [trim(str("^")), 11, :left],
        [trim(str("|")), 12, :left],
        [trim(str("&&") | key("and")), 13, :left],
        [trim(str("||") | key("or")), 14, :left],
        [trim(str("+=") | str("-=") | str("*=") | str("/=") |
              str("%=") | str("<<=") | str(">>=") | str("&=")|
              str("^=") | str("|=") | str("=")), 15, :right]
      )
    }

    # Matches unary operation
    # example: !foo
    rule(:unary_operation) {
      (trim(str("++") | str("--") | key("not") | match['\+\-!']).as(:o) >> value.as(:r)) |
      (value.as(:l) >> trim(str("++") | str("--")).as(:o))
    }

    # Matches value
    rule(:value) {
      condition |
      closure |
      block |
      call |
      ret |
      name |
      literal
    }

    # Matches statement, so everything that is unassignable
    rule(:statement) {
      function
    }

    # Matches word
    rule(:name) {
      skip_key >>
      (
        match['a-zA-Z'] >>
        match['a-zA-Z\-'].repeat
      ).as(:name)
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

    # Matches floats
    rule(:float) {
      integer >>
      (
        str('.') >> match('[0-9]').repeat(1) |
        str('e') >> match('[0-9]').repeat(1)
      )
    }

    rule(:integer) {
      match("[0-9]").repeat(1)
    }

    # Matches number
    rule(:number) {
      (
        float |
        integer
      ).as(:number)
    }

    # Matches literals (strings, numbers)
    rule(:literal) {
      number |
      string
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
      expression_list.maybe.as(:return)
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
            expression_list.as(:arguments)
          )
        )
      ).as(:call)
    }

    # Matches function parameter
    # example a = 1
    rule(:parameter) {
      name >>
      (
        trim(str("=")) >>
        expression.as(:value)
      ).maybe
    }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list) {
      parens(repeat(parameter, trim(str(","))).as(:parameters))
    }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      parens(repeat(expression, trim(str(","))))
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure) {
      (
        parameter_list.maybe >>
        whitespace.maybe >>
        str("->") >>
        body.as(:body)
      ).as(:closure)
    }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (
        key("function") >>
        space.maybe >>
        name >>
        function_body
      ).as(:function)
    }

    # Matches function body
    rule(:function_body) {
      (
        space.maybe >>
        parameter_list.maybe >>
        body.as(:body)
      ) | body.as(:body)
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (
        key("if") >>
        space.maybe >>
        parens(expression.as(:body)) >>
        space.maybe >>
        key("then").maybe >>
        body.as(:if_true) >>
        (
          space.maybe >>
          key("else") >>
          body.as(:if_false)
        ).maybe
      ).as(:condition)
    }
  end
end
