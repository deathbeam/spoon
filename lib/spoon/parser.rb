require "parslet"
require "parslet/convenience"

require "spoon/util/indentparser"

module Spoon
  class Parser < Spoon::Util::IndentParser
    # Matches string and skips space after it
    def sym(value) str(value) >> space? end

    # Stores string as key, matches it and then skips space after it
    def key(value)
      @keys = [] if @keys.nil?
      @keys.push value unless @keys.include? value

      sym(value)
    end

    # Matches only if you are not trying to match any previously stored key
    rule(:skip_key) {
      if @keys.nil? or @keys.empty?
        alwaysmatch
      else
        result = str(@keys.first).absent?

        for keyword in @keys
          result >> str(keyword).absent?
        end

        result
      end
    }

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

    # Matches everything that starts with '#' until end of line
    rule(:comment)     { str("#") >> stop.as(:comment) }

    # Matches all lowercase words except keys, then skips space after them
    rule(:name)        { skip_key >> match["a-z"].repeat(1).as(:name) >> space?}

    # Matches simple numbers
    rule(:number)      { match["0-9"].repeat(1).as(:number) }

    # Matches one or more expressions
    rule(:expressions?)  { expressions.maybe }
    rule(:expressions)   { expression.repeat(1) }
    rule(:expression)    { function | condition | name | number }

    # Matches expression or indented block
    rule(:body)          { block | expression }

    # Matches indented block and consumes newlines at start and in between
    # but not at end
    rule(:block) {
      newline? >> indent >>
        (expression >>
          (newline? >> samedent >> expression).repeat).maybe.as(:block) >>
      dedent
    }

    # Matches functions
    rule(:function) { key("def") >> name.as(:function) >> params.maybe >> body.as(:body) }

    # Matches comma delimited expressions in parenthesis
    rule(:params)   { sym("(") >> (name >> (sym(",") >> name).repeat(0)).maybe.as(:params) >> sym(")") }

    # Matches if-else if-else in recursive structure
    rule(:condition) {
      key("if") >> sym("(") >> expression.as(:condition) >> sym(")") >>
          body.maybe.as(:if) >>
      (key("else") >> body.maybe.as(:else)).maybe
    }

    # Matches entire file, skipping all whitespace at beginning and end
    rule(:root) { whitespace? >> expressions >> whitespace? }
  end
end
