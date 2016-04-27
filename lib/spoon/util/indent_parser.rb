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
      def initialize
        super
        @stack = [0]
        @current = 0
        @last = 0
      end

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
      end

      rule (:checkdent) {
        dynamic { |source, context|
          check_indentation(source)
          AlwaysMatch.new
        }
      }

      rule(:indent) {
        dynamic { |source, context|
          if @current > @last
            AlwaysMatch.new
          else
            NeverMatch.new "Not an indent"
          end
        }
      }

      rule(:dedent) {
        dynamic { |source, context|
          if @current < @last
            # We need to do this, so next samedent won't be skipped
            source.bytepos = source.bytepos - @current
            @current = @last
            
            AlwaysMatch.new
          else
            NeverMatch.new "Not a dedent"
          end
        }
      }

      rule(:samedent) {
        dynamic { |source, context|
          if @current == @last
            AlwaysMatch.new
          else
            NeverMatch.new "Not a samedent"
          end
        }
      }
    end
  end
end
