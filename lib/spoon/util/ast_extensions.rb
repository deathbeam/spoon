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

      def to_b
        str = trim
        return true if str == "true"
        return false if str == "false"
        raise ArgumentError.new("Invalid value for Boolean: \"#{self}\"")
      end
    end
  end
end
