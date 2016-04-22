require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Parslet::Parser
      # Stores string as key, matches it and then skips space after it
      private def store_keyword(value)
        @keywords = [] if @keywords.nil?
        @keywords.push value unless @keywords.include? value

        str(value)
      end

      # Matches only if you are not trying to match any previously stored key
      rule(:skip_key) {
        if @keywords.nil? or @keywords.empty?
          always_match
        else
          result = str(@keywords.first).absent?

          for keyword in @keywords
            result = result >> str(keyword).absent?
          end

          result
        end
      }

      # Matches string and skips space after it
      def sym(value)
        if value.kind_of?(Array)
          result = str(value.first)
          value.each { |val| result |= str(val) }
          result >> space.maybe
        else
          str(value) >> space.maybe
        end
      end

      # Matches keyword and skips space after it
      def key(value)
        if value.kind_of?(Array)
          result = store_keyword(value.first)
          value.each { |val| result |= store_keyword(val) }
          result >> space.maybe
        else
          store_keyword(value) >> space.maybe
        end
      end

      # Matches string or keyword, based on if it is word or not
      def op(value)
        if value.kind_of?(Array)
          result = whitespace.maybe >> (/\w/.match(value.first) ? key(value.first) : sym(value.first))
          value.each { |val| result |= (/\w/.match(val) ? key(val) : sym(val)) }
          result >> whitespace.maybe
        else
          trim(/\w/.match(value) ? key(value) : sym(value))
        end
      end

      # Trims all whitespace around value
      def trim(value) whitespace.maybe >> value >> whitespace.maybe end

      # Matches value in parens or not in parens
      def parens(value) (str("(") >> whitespace.maybe >> value.maybe >> whitespace.maybe >> str(")")) | value end

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
