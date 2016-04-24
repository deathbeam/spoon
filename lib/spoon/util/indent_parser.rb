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
      attr_accessor :msg

      def initialize(msg = "ignore")
        self.msg = msg
      end

      def try(source, context, consume_all)
        context.err(self, source, msg)
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

      rule(:indent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent > last
            @stack.push dent
            AlwaysMatch.new
          else
            NeverMatch.new "Not an indent"
          end
        }
      }

      rule(:dedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent < last
            @stack.pop
            AlwaysMatch.new
          else
            NeverMatch.new "Not a dedent"
          end
        }
      }

      rule(:samedent) {
        dynamic { |source, context|
          last, dent = check_indentation(source)

          if dent == last
            AlwaysMatch.new
          else
            NeverMatch.new "Not a samedent"
          end
        }
      }
    end
  end
end
