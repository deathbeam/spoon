require 'parslet'
require "awesome_print"

module Spoon
  module Util
    class IndentParser < Parslet::Parser
      def initialize
        super
        @stack = [0]
        @current = 0
        @last = 0
      end

      # Check indentation level at current position and adjust stack
      def check_indentation(source)
        indent_level = 0
        matcher = /[ \t]/

        while source.matches?(matcher)
          source.consume(1)
          indent_level += 1
        end

        @last = @stack[@stack.length - 1]
        @current = indent_level

        if @current > @last
          @stack.push @current
        elsif @current < @last
          @stack.pop
        end

        AlwaysMatch.new
      end

      # We need to do this, so next samedent won't be skipped
      def fix_position(source)
        source.bytepos = source.bytepos - @current
        @current = @last
        AlwaysMatch.new
      end

      rule (:checkdent) {
        dynamic { |source, context|
          check_indentation(source)
        }
      }

      rule(:indent) {
        dynamic { |source, context|
          @current > @last ? AlwaysMatch.new : NeverMatch.new("Not an indent")
        }
      }

      rule(:dedent) {
        dynamic { |source, context|
          @current < @last ? fix_position(source) : NeverMatch.new("Not a dedent")
        }
      }

      rule(:samedent) {
        dynamic { |source, context|
          @current == @last ? AlwaysMatch.new : NeverMatch.new("Not a samedent")
        }
      }
    end

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
  end
end
