require "parslet"

module Spoon
  module Util
    class IndentParser < Parslet::Parser
      def initialize
        super
        @stack = [0]
        @prev_stack = [0]
        @current = 0
        @last = 0
        @matcher = /[ \t]/
      end

      # Check indentation level at current position and adjust stack
      def check_indentation(source)
        @current = 0

        while source.matches?(@matcher)
          source.consume(1)
          @current += 1
        end

        @last = @stack[@stack.length - 1]

        if @current > @last
          @prev_stack.push @last
          @stack.push @current
        elsif @current < @last
          while @current != @stack[@stack.length - 1] && !@stack.empty?
            @stack.pop
          end
        end

        AlwaysMatch.new
      end

      # We need to do this, so next samedent won't be skipped
      def fix_position(source)
        source.bytepos = source.bytepos - @current

        if @current <= @prev_stack[@prev_stack.length - 1]
          while @last != @current && !@prev_stack.empty?
            @last = @prev_stack.pop
          end

          return AlwaysMatch.new if @last == @current
        end

        NeverMatch.new "Mismatched indentation level"
      end

      rule(:checkdent) {
        dynamic { |source|
          check_indentation(source)
        }
      }

      rule(:indent) {
        dynamic {
          @current > @last ? AlwaysMatch.new : NeverMatch.new("Not an indent")
        }
      }

      rule(:dedent) {
        dynamic { |source|
          @current < @last ? fix_position(source) : NeverMatch.new("Not a dedent")
        }
      }

      rule(:samedent) {
        dynamic {
          @current == @last ? AlwaysMatch.new : NeverMatch.new("Not a samedent")
        }
      }
    end

    class AlwaysMatch < Parslet::Atoms::Base
      def try(_, _, _)
        succ("")
      end
    end

    class NeverMatch < Parslet::Atoms::Base
      attr_accessor :msg

      def initialize(msg = "ignore")
        self.msg = msg
      end

      def try(source, context, _)
        context.err(self, source, msg)
      end
    end
  end
end
