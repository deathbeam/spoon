require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"
require "spoon/util/parser_extensions"

module Spoon
  class Parser < Spoon::Util::IndentParser
    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root)            { trim(statement.repeat(1) | expressions) }

    # Matches value
    rule(:value)           { condition | closure | chain | ret | name | number }

    # Matches statement (unassignable and unmovable value)
    rule(:statement)       { function }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment)         { str("#") >> stop.as(:comment) }

    # Matches expression or indented block and skips end of line at end
    rule(:body)            { (block | expression) >> newline? }

    # Matches chain of expressions
    # example: abc(a).def(b).efg
    rule(:chain)           { ((call | name) >> (op(".") >> (call | name)).repeat(1)).as(:chain) }

    # Matches function call
    # example: a(b, c, d, e, f)
    rule(:call)            { name >> parens(expression_list.as(:arguments)) }

    # Matches return statement
    # example: return a, b, c
    rule(:ret)            { (key("return") >> parens(expression_list).maybe).as(:return) }

    # Matches closure
    # example: (a) -> b
    rule(:closure)         { (parens(parameter_list.as(:parameters)).maybe >> sym("->") >> body.as(:body)).as(:closure) }

    # Matches function parameter
    # example a = 1
    rule(:parameter)       { name.as(:name) >> (op("=") >> expression.as(:value)).maybe }

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
      (key("def") >> name.as(:name) >>
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
