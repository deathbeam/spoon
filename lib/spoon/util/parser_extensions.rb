require 'to_regexp'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    # Monkey-patch the parser to include some common methods
    class Spoon::Util::IndentParser
      @@templates = {
        ' AND '          => ' >> ',
        ' OR '           => ' | ',
        '?'              => '.maybe',
        '/ \* ([0-9]+)/' => '.repeat(\1)',
        '/:([\w_]+)/'    => '.as(:\1)',
        '/"(.+)"/'       => 'str("\1")',
        '/\/(.+)\//'     => 'match(\'\1\')'
      }

      # DSL for our awesome parser
      def self.template(key, value)
        @@templates[key] = value
      end

      def self.the(name, arr)
        script = ""
        start_rule = "("
        end_rule = ")"
        alias_rule = ""

        arr.each do |item|
          mode = 0
          result = item

          if result.start_with? "start: "
            result = result[7..-1]
            mode = 1
          elsif result.start_with? "end: "
            result = result[5..-1]
            mode = 2
          elsif result.start_with? "alias: "
            result = result[7..-1]
            mode = 3
          elsif item != arr.first
            script += " | "
          end

          @@templates.each do |k, v|
            toreplace = k.to_s

            if k.respond_to? :to_regexp
              toreplace = k.to_regexp || k.to_s
            end

            result = result.gsub(toreplace, v.to_s)
          end

          case mode
          when 1
            start_rule = result + " >> " + start_rule
          when 2
            end_rule = end_rule + " >> " + result
          when 3
            alias_rule = ".as(:" + result + ")"
          end

          if mode > 0
            arr -= [item]
          else
            script += result
          end
        end

        script = start_rule + script + end_rule + alias_rule

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
          result = keyword(value.first)
          value.each { |val| result |= keyword(val) }
          result >> space.maybe
        else
          keyword(value) >> space.maybe
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
      def parens(value) (op("(") >> value.maybe >> op(")")) | value end

      # Matches single or multiple end of lines
      rule(:newline)     { match["\n\r"].repeat(1) }

      # Matches single or multiple spaces, tabs and comments
      rule(:space)       { (match("\s") | comment).repeat(1) }

      # Matches all whitespace (tab, end of line, space, comments)
      rule(:whitespace)  { (match["\s\n\r"] | comment).repeat(1) }

      # Matches everything until end of line
      rule(:stop)        { match["^\n"].repeat }

      # Dummy comment rule, override in implementation
      rule(:comment)     { never_match }
    end
  end
end