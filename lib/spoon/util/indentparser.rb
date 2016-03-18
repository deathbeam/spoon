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
          indent = 0

          while source.matches?(Regexp.new("[ \t]"))
            source.consume(1)
            indent += 1
          end

          @stack = [0] if @stack.nil?

          return @stack[@stack.length - 1], indent
        end

        rule(:indent) {
          dynamic { |source, context|
            last, dent = check_indentation(source)

            if dent > last
              @stack.push dent
              AlwaysMatch.new
            else
              NeverMatch.new
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
              NeverMatch.new
            end
          }
        }

        rule(:samedent) {
          dynamic { |source, context|
            last, dent = check_indentation(source)

            if dent == last
              AlwaysMatch.new
            else
              NeverMatch.new
            end
          }
        }

=begin
        rule(:identifier) { match['A-Za-z0-9'].repeat(1).as(:identifier) >> match("\n").maybe }

        rule(:expression) { node | identifier}

        rule(:node) {
          identifier >>
            indent >>
              (expression >> (samedent >> expression).repeat).as(:children) >>
            dedent
        }

        rule(:document) { expression.repeat }

        root :document
=end
    end
  end
end
