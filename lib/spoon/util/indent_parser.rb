require 'parslet'
require "awesome_print"

module Spoon
  module Util
    class AlwaysMatch < Parslet::Atoms::Base
      def try(source, context, consume_all)
        succ("")
      end
    end

    class NeverMatch < Parslet::Atoms::Base
      def try(source, context, consume_all)
        context.err(self, source, "ignore")
      end
    end

    class IndentParser < Parslet::Parser
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
            result >> str(keyword).absent?
          end

          result
        end
      }

      def check_indentation(source)
        indent = 0

        while source.matches?(Regexp.new("[ \t]"))
          source.consume(1)
          indent += 1
        end

        @stack = [0] if @stack.nil?

        return @stack[@stack.length - 1], indent
      end

      rule(:alwaysmatch) {
        AlwaysMatch.new
      }

      rule(:nevermatch) {
        NeverMatch.new
      }

      rule(:indent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent > last
            @stack.push dent
            alwaysmatch
          else
            nevermatch
          end
        }
      }

      rule(:dedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent < last
            @stack.pop
            alwaysmatch
          else
            nevermatch
          end
        }
      }

      rule(:samedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent == last
            alwaysmatch
          else
            nevermatch
          end
        }
      }
    end
  end
end
