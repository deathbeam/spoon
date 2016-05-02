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

      def to_op
        str = trim

        # Special
        return "access" if str == "."

        # Assign and update
        return "assign" if str == "="
        return "addition assign" if str == "+="
        return "subtraction assign" if str == "-="
        return "multiplication assign" if str == "*="
        return "division assign" if str == "/="
        return "and assign" if str == "&="
        return "or assign" if str == "|="
        return "xor assign" if str == "^="
        return "modulo assign" if str == "%="

        # Logical
        return "not" if str == "!"
        return "and" if str == "&&"
        return "or" if str == "||"

        # Arithmetic
        return "increment" if str == "++"
        return "decrement" if str == "--"
        return "addition" if str == "+"
        return "subtraction" if str == "-"
        return "multiplication" if str == "*"
        return "division" if str == "/"
        return "modulo" if str == "%"

        # Comparison
        return "equal" if str == "==" || str == "is"
        return "not equal" if str == "!=" || str == "isnt"
        return "less than" if str == "<"
        return "less than or equal" if str == "<="
        return "greater than" if str == ">"
        return "greater than or equal" if str == ">="

        # Bitwise
        return "bitwise not" if str == "~"
        return "bitwise and" if str == "&"
        return "bitwise or" if str == "|"
        return "bitwise xor" if str == "^"
        return "shift left" if str == "<<"
        return "shift right" if str == ">>"
        return "unsigned shift right" if str == ">>>"

        return str
      end
    end
  end
end
