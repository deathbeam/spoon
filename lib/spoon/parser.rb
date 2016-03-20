require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"

module Spoon
  class Parser < Spoon::Util::IndentParser
    # Matches string and skips space after it
    def sym(value) str(value) >> space? end

    # Matches keyword and skips space after it
    def key(value) keyword(value) >> space? end

    # Matches string or keyword, based on if it is word or not
    def op(value) /\w/.match(value) ? key(value) : sym(value) end

    # Matches value in parens or not in parens
    def parens(value) sym("(").maybe >> value >> sym(")").maybe end

    # Matches single or multiple end of lines
    rule(:newline)     { match["\n\r"].repeat(1) }
    rule(:newline?)    { newline.maybe }

    # Matches single or multiple spaces, tabs and comments
    rule(:space)       { (match("\s") | comment).repeat(1) }
    rule(:space?)      { space.maybe }

    # Matches all whitespace (tab, end of line, space, comments)
    rule(:whitespace)  { (match["\s\n\r"] | comment).repeat(1) }
    rule(:whitespace?) { whitespace.maybe }

    # Matches everything until end of line
    rule(:stop)        { match["^\n"].repeat }

    # Matches value
    rule(:value)    { function | condition | closure | name | number }

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) { whitespace? >> expressions >> whitespace? }

    # Matches indented block and consumes newlines at start and in between
    # but not at end
    rule(:block) {
      newline? >> indent >>
        (expression >>
          (newline? >> samedent >> expression).repeat).maybe.as(:block) >>
      dedent
    }

    # Matches expression or indented block and skips end of line at end
    rule(:body)     { (block | expression) >> newline? }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment)  { str("#") >> stop.as(:comment) }

    # Matches all lowercase words except keys, then skips space after them
    # example: abc
    rule(:name)     { skip_key >> match["a-z"].repeat(1).as(:name) >> space? }

    # FIXME: Should match chain of expressions
    # example: abc(a).def(b).efg
    rule(:chain)    { ((name | call) >> (sym(".") >> name | call).repeat(0)).maybe.as(:chain) }

    # FIXME: Should match function call
    # example: a(b, c, d, e, f)
    rule(:call)     { name >> sym("(").maybe >> expression_list >> sym(")").maybe }

    # Matches simple numbers
    # example: 123
    rule(:number)   { match["0-9"].repeat(1).as(:number) }

    # Matches function definition
    # example: def (a) b
    rule(:function) {
      (key("def") >> name.as(:name) >>
        (body.as(:body) | parens(params).maybe >> body.as(:body))).as(:function)
    }

    # Matches closure
    # example: (a) -> b
    rule(:closure)  { (parens(params).maybe >> sym("->") >> body.as(:body)).as(:closure) }

    # Matches comma delimited function params in parenthesis
    # example: (a, b)
    rule(:params)   { (name >> (sym(",") >> name).repeat(0)).maybe.as(:params) }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      (key("if") >> parens(expression.as(:body)) >>
          body.maybe.as(:if_true) >>
      (key("else") >> body.maybe.as(:if_false)).maybe).as(:condition)
    }

    rule(:operator) {
      # FIXME: For some reason, regex below is not working
      # match["\+\-\*\/%\^><\|&"] |
        whitespace? >> (op("or") | op("and") | op("<=") |
        op(">=") | op("!=") | op("==")) >> whitespace?
    }

    rule(:assign) { sym("=") >> expression_list.as(:assign) }

    rule(:update) {
      (whitespace? >> (sym("+=") | sym("-=") | sym("*=") | sym("/=") |
      sym("%=") | sym("or=") | sym("and=")) >> whitespace? >> expression).as(:update)
    }

    # Matches one or more exressions
    rule(:expressions?) { expressions.maybe }
    rule(:expressions) { expression.repeat(1) }
    rule(:expression) { value.as(:left) >> (operator.as(:op) >> value.as(:right)).maybe }

    # Matches comma delimited expressions
    # example: a(b), c(d), e
    rule(:expression_list) { (expression >> (sym(",") >> expression).repeat(0)) }
  end
end
