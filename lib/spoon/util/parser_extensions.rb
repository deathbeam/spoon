require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Parslet::Parser
      def initialize
        super
        @keywords = []
      end

      # Matches only if you are not trying to match any previously stored key
      rule(:skip_key) {
        result = str(@keywords.first).absent?

        for keyword in @keywords
          result = result >> str(keyword).absent?
        end

        result
      }

      # Stores string as key and matches it
      def key(value)
        @keywords.push value unless @keywords.include? value
        str(value)
      end

      # Trims all whitespace around value
      def trim(value) whitespace.maybe >> value >> whitespace.maybe end

      # Matches value in parens or not in parens
      def parens(value) (str("(") >> whitespace.maybe >> value >> whitespace.maybe >> str(")")) | value end

      # Matches single or multiple end of lines
      rule(:newline)     { match["\n\r"].repeat(1) }

      # Matches single or multiple spaces, tabs and comments
      rule(:space)       { (match("\s") | comment).repeat(1) }

      # Matches all whitespace (tab, end of line, space, comments)
      rule(:whitespace)  { (match["\s\n\r"] | comment).repeat(1) }

      # Matches everything until end of line
      rule(:stop)        { match["^\n"].repeat }

      # Matches empty line
      rule(:emptyline)   { (match["\n\r"] >> match("\s").repeat >> match["\n\r"]) | match["\n\r"] }

      # Matches space to end of line
      rule(:endofline)   { space.maybe >> emptyline.repeat(1) }

      # Dummy comment rule, override in implementation
      rule(:comment)     { never_match }
    end
  end
end
