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
      def check_indentation(source)
        @stack = [0] if @stack.nil?
        indent = 0
        matcher = /[ \t]/

        while source.matches?(matcher)
          source.consume(1)
          indent += 1
        end

        return @stack[@stack.length - 1], indent
      end

      rule(:always_match) {
        AlwaysMatch.new
      }

      rule(:never_match) {
        NeverMatch.new
      }

      rule(:indent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent > last
            @stack.push dent
            always_match
          else
            never_match
          end
        }
      }

      rule(:dedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent < last
            @stack.pop
            always_match
          else
            never_match
          end
        }
      }

      rule(:samedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)
          dent == last ? always_match : never_match
        }
      }
    end
  end
end
