require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Spoon::Util::IndentParser
      @@storage = {
        " AND " => " >> ",
        " OR " => " | ",
        "?" => ".maybe"
      }

      # DSL for our awesome parser
      def self.store(key, value)
        @@storage[key] = value
      end

      def self.the(name, arr)
        arr.map! do |item|
          temp = item
          @@storage.each { |k, v| temp = temp.gsub(k.to_s, v.to_s) }
          item = temp
        end

        script = arr.join(" | ")
          .gsub(/ \* ([0-9]+)/, '.repeat(\1)')
          .gsub(/((?:\w+)|(?:\(.+\))):(\w+)/, '\1.as(:\2)')

        puts script

        rule(name) { eval(" " + script) }
      end

      # Stores string as key, matches it and then skips space after it
      def keyword(value)
        @keywords = [] if @keys.nil?
        @keywords.push value unless @keywords.include? value

        str(value)
      end

      # Matches only if you are not trying to match any previously stored key
      rule(:skip_key) {
        if @keywords.nil? or @keywords.empty?
          alwaysmatch
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
      rule(:word)        { skip_key >> match["a-z\-"].repeat(1).as(:word) >> space? }

      # Matches numbers
      # example: 123
      rule(:number)      { (float | integer) >> space? }
      rule(:integer)     { match["0-9"].repeat(1) }
      rule(:float)       { match["0-9"] >> match["0-9\."].repeat(1) }

      # Matches everything until end of line
      rule(:stop)        { match["^\n"].repeat }

      # Dummy comment rule, override in implementation
      rule(:comment)     { nevermatch }
    end
  end
end
