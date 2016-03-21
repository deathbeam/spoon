require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Spoon::Util::IndentParser
      # Matches string and skips space after it
      def sym(value)
        if value.kind_of?(Array)
          result = str(value.first)
          value.each { |val| result |= str(val) }
          result >> space?
        else
          str(value) >> space?
        end
      end

      # Matches keyword and skips space after it
      def key(value)
        if value.kind_of?(Array)
          result = keyword(value.first)
          value.each { |val| result |= keyword(val) }
          result >> space?
        else
          keyword(value) >> space?
        end
      end

      # Matches string or keyword, based on if it is word or not
      def op(value)
        if value.kind_of?(Array)
          result = whitespace? >> (/\w/.match(value.first) ? key(value.first) : sym(value.first))
          value.each { |val| result |= (/\w/.match(val) ? key(val) : sym(val)) }
          result >> whitespace?
        else
          trim(/\w/.match(value) ? key(value) : sym(value))
        end
      end

      # Trims all whitespace around value
      def trim(value) whitespace? >> value >> whitespace? end

      # Matches value in parens or not in parens
      def parens(value) (op("(") >> value.maybe >> op(")")) | value end

      # Matches single or multiple end of lines
      rule(:newline)     { match["\n\r"].repeat(1) }
      rule(:newline?)    { newline.maybe }

      # Matches single or multiple spaces, tabs and comments
      rule(:space)       { (match("\s") | comment).repeat(1) }
      rule(:space?)      { space.maybe }

      # Matches all whitespace (tab, end of line, space, comments)
      rule(:whitespace)  { (match["\s\n\r"] | comment).repeat(1) }
      rule(:whitespace?) { whitespace.maybe }

      # Matches all lowercase words except keys, then skips space after them
      # example: abc
      rule(:name)        { skip_key >> match["a-z\-"].repeat(1).as(:name) >> space? }

      # Matches numbers
      # example: 123
      rule(:number)      { float | integer }
      rule(:integer)     { match["0-9"].repeat(1).as(:integer) }
      rule(:float)       { match["0-9"] >> match["0-9\."].repeat(1).as(:float) }

      # Matches everything until end of line
      rule(:stop)        { match["^\n"].repeat }

      # Dummy comment rule, override in implementation
      rule(:comment)     { nevermatch }
    end
  end
end
