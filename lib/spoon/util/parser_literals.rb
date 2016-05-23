require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  module Util
    class Spoon::Util::IndentParser
      attr_accessor :keywords

      def keywords
        [
          :if,
          :else,
          :return,
          :and,
          :is,
          :isnt,
          :or,
          :not,
          :then,
          :in,
          :for,
          :unless,
          :do,
          :while,
          :import,
          :class,
          :switch,
          :when,
          :try,
          :catch,
          :to
        ]
      end

      ####################################
      # Special keywords
      ####################################

      rule(:DO)       { key :do }

      rule(:ELSE)     { key :else }

      rule(:FOR)      { key :for }

      rule(:IF)       { key :if }

      rule(:IMPORT)   { key :import }

      rule(:IN)       { key :in }

      rule(:RETURN)   { key :return }

      rule(:THEN)     { key :then }

      rule(:UNLESS)   { key :unless }

      rule(:WHILE)    { key :while }

      rule(:NEW)      { key :new }

      rule(:CLASS)    { key :class }

      rule(:SWITCH)   { key :switch }

      rule(:WHEN)     { key :when }

      rule(:TRY)      { key :try }

      rule(:CATCH)    { key :catch }

      ####################################
      # Special characters
      ####################################

      rule(:ARROW)       { str "->" }

      rule(:FAT_ARROW)   { str "=>" }

      rule(:EXCLAMATION) { str "!" }

      rule(:HASH)        { str "#" }

      rule(:STAR)        { str "*" }

      rule(:DOUBLE_DOT)  { trim(str(":")) }

      ####################################
      # Operators
      ####################################

      # Dot
      rule(:DOT) { trim(str(".") >> str(".").absent? ) }

      # Comma
      rule(:COMMA) { trim(str(",")) }

      # Range
      rule(:RANGE) { trim(str("..") | key("to")) }

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

      # Suffix/Prefix increment and decrement
      rule(:INCREMENT) { str("++") | str("--") }

      # Unary plus/minus, logical not and bitwise not
      rule(:UNARY) { key("not") | match['\+\-!~'] }

      # Direct assignment
      rule(:ASSIGN) { trim(str("=")) }

      # Compound assignment
      rule(:CASSIGN) {
        trim(str("+=") | str("-=") | str("*=") | str("/=") |
            str("%=") | str("<<=") | str(">>=") | str("&=")|
            str("^=") | str("|="))
      }
    end
  end
end
