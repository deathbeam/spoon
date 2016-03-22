require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"

module Spoon
  class Parser < Spoon::Util::IndentParser
    store :HASH,   'key("#")'
    store :DOT,    'op(".")'
    store :RETURN, 'key("return")'

    # Matches entire file, skipping all whitespace at beginning and end
    the :root, [
      'trim statement * 1',
      'expression * 1'
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

    # Matches closure
    # example: (a) -> b
    rule(:closure)         { (parens(parameter_list.as(:parameters)).maybe >> sym("->") >> body.as(:body)).as(:closure) }

    # Matches function parameter
    # example a = 1
    rule(:parameter)       { word.as(:name) >> (op("=") >> expression.as(:value)).maybe }

    # Matches comma delimited function parameters
    # example: (a, b)
    rule(:parameter_list)  { (parameter >> (op(",") >> parameter).repeat(0)) }

    # Matches one or more exressions
    rule(:expressions?)    { expressions.maybe }
    rule(:expressions)     { expression.repeat(1) }
    rule(:expression)      { (value.as(:left) >> operator >> value.as(:right)) | value }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) { (expression >> (op(",") >> expression).repeat(0)) }

    # Matches indented block and consumes newlines at start and in between
    # but not at end
    rule(:block) {
      newline? >> indent >>
        (expression >>
          (newline? >> samedent >> expression).repeat).maybe.as(:block) >>
      dedent
    }

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

    rule(:operator) {
      (op(["or", "and", "<=", ">=", "!=", "==", "+=", "-=", "*=", "/=", "%=", "or=", "and="]) | trim(match['\+\-\*\/%\^><\|&='])).as(:op)
    }
  end
end
