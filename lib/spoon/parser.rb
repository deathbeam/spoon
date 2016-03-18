require "parslet"
require "parslet/convenience"

require "spoon/util/indent_parser"

module Spoon
  class Parser < Spoon::Util::IndentParser
    # Matches string and skips space after it
    def sym(value) str(value) >> space? end

    # Matches keyword and skips space after it
    def key(value) keyword(value) >> space? end

    # Matches single or multiple end of lines
    rule(:newline)     { (match("\n") | match("\r")).repeat(1) }
    rule(:newline?)    { newline.maybe }

    # Matches single or multiple spaces, tabs and comments
    rule(:space)       { (match("\s") | comment).repeat(1) }
    rule(:space?)      { space.maybe }

    # Matches all whitespace (tab, end of line, space, comments)
    rule(:whitespace)  { (match("\s") | match("\n") | match("\r") | comment).repeat(1) }
    rule(:whitespace?) { whitespace.maybe }

    # Matches everything until end of line
    rule(:stop)        { match["^\n"].repeat }

    # Matches one or more expressions
    rule(:expressions?)  { expressions.maybe }
    rule(:expressions)   { expression.repeat(1) }
    rule(:expression)    { function | condition | name | number }

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
    rule(:body)          { (block | expression) >> newline? }

    # Matches everything that starts with '#' until end of line
    # example: # abc
    rule(:comment)     { str("#") >> stop.as(:comment) }

    # Matches all lowercase words except keys, then skips space after them
    # example: abc
    rule(:name)        { skip_key >> match["a-z"].repeat(1).as(:name) >> space?}

    # Matches simple numbers
    # example: 123
    rule(:number)      { match["0-9"].repeat(1).as(:number) }

    # Matches function definition
    # example: def (a) b
    rule(:function) { key("def") >> name.as(:function) >> params.maybe >> body.as(:body) }

    # Matches closure
    # example: (a) -> b
    rule(:closure) { params.maybe >> sym("->") >> body.as(:body) }

    # Matches comma delimited function params in parenthesis
    # example: (a, b)
    rule(:params)   { sym("(") >> (name >> (sym(",") >> name).repeat(0)).maybe.as(:params) >> sym(")") }

    # Matches if-else if-else in recursive structure
    # example: if (a) b else if(c) d else e
    rule(:condition) {
      key("if") >> sym("(") >> expression.as(:condition) >> sym(")") >>
          body.maybe.as(:if) >>
      (key("else") >> body.maybe.as(:else)).maybe
    }
  end
end
