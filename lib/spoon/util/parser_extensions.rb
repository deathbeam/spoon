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

      # Stores string as key and matches it
      def key(value)
        @keywords.push value unless @keywords.include? value
        str(value)
      end

      # Trims all whitespace around value
      def trim(value)
        whitespace.maybe >>
        value >>
        whitespace.maybe
      end

      # Matches value in parens or not in parens
      def parens(value)
        (
          str("(") >>
          whitespace.maybe >>
          value.maybe >>
          whitespace.maybe >>
          str(")") >>
          skipline.maybe
        ) |
        value
      end

      # Matches only if you are not trying to match any previously stored key
      rule(:skip_key) {
        result = str(@keywords.first).absent?

        for keyword in @keywords
          result = result >> str(keyword).absent?
        end

        result
      }

      # Matches single or multiple end of lines
      rule(:newline) {
        match["\n\r"]
      }

      # Matches single or multiple spaces, tabs and comments
      rule(:space) {
        (
          comment |
          match("\s")
        ).repeat(1)
      }

      # Matches all whitespace (tab, end of line, space, comments)
      rule(:whitespace) {
        (
          comment |
          match["\s\n\r"]
        ).repeat(1)
      }

      # Matches everything until end of line
      rule(:stop) {
        match["^\n"].repeat
      }

      # Matches space to end of line
      rule(:skipline) {
        (
          space.maybe >>
          newline
        ).repeat(1)
      }

      # Dummy comment rule, override in implementation
      rule(:comment) {
        NeverMatch.new
      }
    end
  end
end
