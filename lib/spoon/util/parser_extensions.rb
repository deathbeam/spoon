require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Spoon::Util::IndentParser

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
        @keywords = [] if @keywords.nil?
        @keywords.push value unless @keywords.include? value
        str(value)
      end

      # Trims all whitespace around value
      def trim(value)
        whitespace.maybe >> value >> whitespace.maybe
      end

      # Repeat parameter using delimiter
      def repeat(value, delimiter, min = 0)
        value >> (delimiter >> value).repeat(min)
      end

      # Matches value in parens or not in parens
      def parens(value)
        (str("(") >> trim(value.maybe) >> str(")") >> endline.maybe) | value
      end

      # Matches single or multiple end of lines
      rule(:newline) {
        match["\n\r"]
      }

      # Matches single or multiple spaces, tabs and comments
      rule(:space) {
        (comment | match("\s")).repeat(1)
      }

      # Matches all whitespace (tab, end of line, space, comments)
      rule(:whitespace) {
        (comment | match["\s\n\r"]).repeat(1)
      }

      # Matches everything until end of line
      rule(:stop) {
        match["^\n"].repeat
      }

      # Matches space to end of line and checks indentation
      rule(:endline) {
        (space.maybe >> newline).repeat(1) >> checkdent
      }

      rule(:op_compound_assign) {
        str("-=") |
        str("+=") |
        str("/=") |
        str("*=") |
        str("%=") |
        str("||=") |
        str("&&=") |
        str(">>>=") |
        str("<<=") |
        str(">>=") |
        str("&=") |
        str("^=") |
        str("|=")
      }

      rule(:op_shift) {
        str(">>>") |
        str(">>") |
        str("<<")
      }

      rule(:op_math) {
        str("%") |
        str("/") |
        str("*") |
        str("\\")
      }

      rule(:op_compare) {
        str(">=") |
        str("<=") |
        str(">") |
        str("<") |
        str("!=") |
        str("==")
      }

      rule(:op_relation) {
        key("of") |
        key("in")
      }

      rule(:op_logic) {
        str("||") |
        str("&&") |
        str("|") |
        str("&") |
        str("^")
      }

      rule(:op_unary_math) {
        str("!") |
        str("~")
      }
    end
  end
end
