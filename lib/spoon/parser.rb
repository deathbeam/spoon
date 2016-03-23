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
    the :root, [
      'start: whitespace?',
      'end: whitespace?',
      'statement * 1',
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
      'end: newline?',
      'block',
      'expression'
    ]

    # Matches chain value
    the :chain_value, [
      'call',
      'word'
    ]

    # Matches chain of expressions
    # example: abc(a).def(b).efg
    the :chain, [
      'alias: chain',
      'chain_value AND (DOT AND chain_value) * 1'
    ]

    # Matches function call
    # example: a(b, c, d, e, f)
    the :call, [
      'word AND parens(expression_list:arguments)'
    ]

    # Matches return statement
    # example: return a, b, c
    the :ret, [
      'alias: return',
      'RETURN AND parens(expression_list)?'
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
      'parameter AND (COMMA AND parameter) * 0'
    ]

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    the :expression_list, [
      'expression AND (COMMA AND expression) * 0'
    ]

    # Matches operator
    the :operator, [
      'op(["or", "and", "<=", ">=", "!=", "==", "+=", "-=", "*=", "/=", "%=", "or=", "and="])',
      'whitespace? AND match(\'[\+\-\*\/%\^><\|&=]\'):op AND whitespace?'
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
      'word:name AND (op("=") AND expression:value)?'
    ]

    # Matches expression
    the :expression, [
      '(value:left AND operator AND value:right)',
      'value'
    ]

    # Matches function definition
    # example: def (a) b
    the :function, [
      'alias: function',
      'DEF AND word:name AND function_body'
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
      'IF AND parens(expression:body) AND body:if_true AND '\
      '(ELSE AND body:if_false)?'
    ]
  end
end
