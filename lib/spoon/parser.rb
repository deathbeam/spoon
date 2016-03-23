require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"

module Spoon
  class Parser < Spoon::Util::IndentParser
    store :COMMA,  'op(",")'
    store :HASH,   'key("#")'
    store :DOT,    'op(".")'
    store :RETURN, 'key("return")'

    # Matches entire file, skipping all whitespace at beginning and end
    the :root, [
      'whitespace? AND statement * 1 AND whitespace?',
      'whitespace? AND expression * 1 AND whitespace?'
    ]

    # Matches value
    the :value, [
      'condition',
      'closure',
      'chain',
      'ret',
      'word',
      'number'
    ]

    # Matches statement, so everything that is unassignable
    the :statement, [
      'function'
    ]

    # Matches everything that starts with '#' until end of line
    # example: # abc
    the :comment, [
      'HASH AND stop:comment'
    ]

    # Matches expression or indented block and skips end of line at end
    the :body, [
      '(block OR expression) AND newline?'
    ]

    # Matches chain value
    the :chain_value, [
      'call',
      'word'
    ]

    # Matches chain of expressions
    # example: abc(a).def(b).efg
    the :chain, [
      '(chain_value AND (DOT AND chain_value) * 1):chain'
    ]

    # Matches function call
    # example: a(b, c, d, e, f)
    the :call, [
      'word AND parens(expression_list:arguments)'
    ]

    # Matches return statement
    # example: return a, b, c
    the :ret, [
      '(RETURN AND parens(expression_list)?):return'
    ]

    # Matches indented block and consumes newlines at start and in between
    # but not at end
    the :block, [
      'newline? AND indent AND '\
      '(expression AND '\
      '(newline? AND samedent AND expression) * 0)?:block AND '\
      'dedent'
    ]

    # Matches comma delimited function parameters
    # example: (a, b)
    the :parameter_list, [
      '(parameter AND (COMMA AND parameter) * 0)'
    ]

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    the :expression_list, [
      '(expression AND (COMMA AND expression) * 0)'
    ]

    # Matches operator
    the :operator, [
      'op(["or", "and", "<=", ">=", "!=", "==", "+=", "-=", "*=", "/=", "%=", "or=", "and="])',
      'whitespace? AND match(\'[\+\-\*\/%\^><\|&=]\'):op AND whitespace?'
    ]

    # Matches closure
    # example: (a) -> b
    rule(:closure)         { (parens(parameter_list.as(:parameters)).maybe >> sym("->") >> body.as(:body)).as(:closure) }

    # Matches function parameter
    # example a = 1
    rule(:parameter)       { word.as(:name) >> (op("=") >> expression.as(:value)).maybe }

    # Matches expression
    rule(:expression)      { (value.as(:left) >> operator >> value.as(:right)) | value }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (key("def") >> word.as(:name) >>
        (parens(parameter_list.as(:parameters)).maybe >> body.as(:body) | body.as(:body))).as(:function)
    }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (key("if") >> parens(expression.as(:body)) >>
          body.as(:if_true) >>
      (key("else") >> body.as(:if_false)).maybe).as(:condition)
    }
  end
end
