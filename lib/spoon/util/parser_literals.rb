require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    class Spoon::Util::IndentParser
      ####################################
      # Special keywords
      ####################################

      rule(:DO) { key("do") }

      rule(:ELSE) { key("else") }

      rule(:FOR) { key("for") }

      rule(:FUNCTION) { key("function") }

      rule(:IF) { key("if") }

      rule(:IN) { key("in") }

      rule(:RETURN) { key("return") }

      rule(:THEN) { key("then") }

      rule(:WHILE) { key("while") }

      ####################################
      # Special characters
      ####################################

      rule(:ARROW) { str("->") }

      rule(:EXCLAMATION) { str("!") }

      rule(:HASH) { str("#") }

      ####################################
      # Operators
      ####################################

      # Dot
      rule(:DOT) { trim(str(".")) }

      # Comma
      rule(:COMMA) { trim(str(",")) }

      # Multiplication, division, and remainder
      rule(:MUL) { trim(match['\*/%']) }

      # Addition and subtraction
      rule(:ADD) { trim(match['\+\-']) }

      # Bitwise left shift and right shift
      rule(:SHIFT) { trim(str("<<") | str(">>")) }

      # For relational operators <, ≤ > and ≥ respectively
      rule(:COMPARE) { trim(match['<>'] |str("<=") | str(">=")) }

      # For relational operators = and ≠ respectively
      rule(:EQ) { trim(str("==") | str("!=") | key("is") | key("isnt")) }

      # Bitwise AND
      rule(:BAND) { trim(str("&")) }

      # Bitwise XOR
      rule(:BXOR) { trim(str("^")) }

      # Bitwise OR
      rule(:BOR) { trim(str("|")) }

      # Logical AND
      rule(:AND) { trim(str("&&") | key("and")) }

      # Logical OR
      rule(:OR) { trim(str("||") | key("or")) }

      # Direct assignment
      rule(:ASSIGN) {
        trim(str("="))
      }

      # Compound assignment
      rule(:CASSIGN) {
        trim(str("+=") | str("-=") | str("*=") | str("/=") |
            str("%=") | str("<<=") | str(">>=") | str("&=")|
            str("^=") | str("|="))
      }

      # Suffix/Prefix increment and decrement
      rule(:INCREMENT) { str("++") | str("--") }

      # Unary plus/minus, logical not and bitwise not
      rule(:UNARY) { key("not") | match['\+\-!~'] }
    end
  end
end
