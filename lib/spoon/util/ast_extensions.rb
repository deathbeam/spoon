require 'ast/node'

module Spoon
  module Util
    class AST::Node
      def option(variable)
        variable = "@#{variable}"
        instance_variable_get(variable)
      end
    end

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
        raise ArgumentError.new("Invalid value for boolean: \"#{self}\"")
      end

      def to_op
        str = trim

        return "..." if str == ".."
        return "!" if str == "not"
        return "&&" if str == "and"
        return "||" if str == "or"
        return  "==" if str == "is"
        return "!=" if str == "isnt"

        return str
      end
    end
  end
end
