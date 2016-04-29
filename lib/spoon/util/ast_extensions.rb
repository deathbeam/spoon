require 'ast/node'

module Spoon
  module Util
    class Parslet::Slice
      def to_v
        "#{self}"
      end

      def trim
        str = to_v
        str.strip! || str
      end
    end
  end
end
