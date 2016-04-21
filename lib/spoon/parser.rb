require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"

module Spoon
  class Parser < Spoon::Util::IndentParser
    template :COMMA,  'op(",")'
    template :HASH,   'key("#")'
    template :DOT,    'op(".")'
    template :RETURN, 'key("return")'
    template :ARROW,  'sym("->")'
    template :DEF,    'key("def")'
    template :IF,     'key("if")'
    template :ELSE,   'key("else")'

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) {
      whitespace.maybe >>
      (statement| expression).repeat(1) >>
      whitespace.maybe
    }

    # Matches word
    rule(:word) {
      skip_key >>
      match['a-z\-'].repeat(1).as(:word) >>
      space.maybe
    }

    # Matches number
    rule(:number) {
      space.maybe >>
      match["0-9"].repeat(1)
    }

    # Matches literals (strings, numbers)
    rule(:literal) {
      number
    }

    # Matches value
    rule(:value) {
      condition |
      closure |
      chain |
      ret |
      word |
      literal
    }

    # Matches statement, so everything that is unassignable
    rule(:statement) {
      function
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
      word
    }

    # Matches chain of expressions
    # example: abc(a).def(b).efg
    rule(:chain) {
      (chain_value >> (op(".") >> chain_value).repeat(1)).as(:chain)
    }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call) {
      word >>
      parens(expression_list.as(:arguments))
    }

    # Matches return statement
    # example: return a, b, c
    rule(:ret) {
      key("return") >> (parens(expression_list).maybe).as(:return)
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

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) {
      expression >> (op(",") >> expression).repeat
    }

    # Matches operator
    the :operator, [
      'alias: op',
      'start: whitespace?',
      'end: whitespace?',
      '"or"',
      '"and"',
      '"is"',
      '"isnt"',
      '"<="',
      '">="',
      '"!="',
      '"=="',
      '"+="',
      '"-="',
      '"*="',
      '"/="',
      '"%="',
      '"or="',
      '"and="',
      '/[\+\-\*\/%\^><\|&=]/'
    ]

    # Matches closure
    # example: (a) -> b
    the :closure, [
      'alias: closure',
      'parens(parameter_list:parameters)? AND ARROW AND body:body'
    ]

    # Matches function parameter
    # example a = 1
    the :parameter, [
      'word:name AND (trim("=") AND expression:value)?'
    ]

    # Matches expression
    the :expression, [
      'value:left AND operator AND value:right',
      'value'
    ]

    # Matches function definition
    # example: def (a) b
    the :function, [
      'alias: function',
      'start: DEF',
      'word:name AND function_body'
    ]

    # Matches function body
    the :function_body, [
      'parens(parameter_list:parameters)? AND body:body',
      'body:body'
    ]

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    the :condition, [
      'alias: condition',
      'start: IF',
      'end: (ELSE AND body:if_false)?',
      'parens(expression:body) AND body:if_true'
    ]
  end
end
