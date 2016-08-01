require 'parslet'
require 'spoon/util/indent_parser'

module Spoon
  class Lexer < Spoon::Util::IndentParser
    attr_accessor :keywords

    def keywords
      [
        :ifdef,
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
        :to,
        :until,
        :extends
      ]
    end

    # Matches only if you are not trying to match any previously stored key
    rule(:skip_key) {
      @keywords = keywords if @keywords.nil?
      result = key(@keywords.first).absent?

      for keyword in @keywords
        result = result >> key(keyword).absent? unless keyword.equal? @keywords.first
      end

      result
    }

    # Stores string as key
    def preserve(value)
      @keywords = keywords if @keywords.nil?
      @keywords.push value unless @keywords.include? value
    end

    # Stores string as key and matches it
    def key(value)
      preserve(value)
      str(value) >> match['a-zA-Z0-9-'].absent?
    end

    # Trims all whitespace around value
    def trim(value)
      whitespace.maybe >> value >> whitespace.maybe
    end

    # Repeat parameter using delimiter
    def repeat(value, delimiter, min = 0)
      value >> (delimiter >> value).repeat(min)
    end

    # Matches value in parens or not in parens
    # FIXME: Ignore parens in parser output (wait for new Parslet release)
    def parens(value, force = false)
      if force
        str("(") >> trim(value) >> str(")") >> endline.maybe
      else
        (str("(") >> trim(value.maybe) >> str(")") >> endline.maybe) | value
      end
    end

    # Matches single or multiple end of lines
    rule(:newline) {
      match["\n\r"]
    }

    # Matches single or multiple spaces, tabs and comments
    rule(:space) {
      (comment | match("\s")).repeat(1)
    }

    # Matches all whitespace (tab, end of line, space, comments)
    rule(:whitespace) {
      (comment | match["\s\n\r"]).repeat(1)
    }

    # Matches everything until end of line
    rule(:stop) {
      match["^\n"].repeat
    }

    # Matches space to end of line and checks indentation
    rule(:endline) {
      (space.maybe >> newline).repeat(1) >> checkdent
    }

    ####################################
    # Special keywords
    ####################################

    rule(:DO)       { key :do }

    rule(:ELSE)     { key :else }

    rule(:FOR)      { key :for }

    rule(:IFDEF)    { key :ifdef }

    rule(:IF)       { key :if }

    rule(:IMPORT)   { key :import }

    rule(:IN)       { key :in }

    rule(:RETURN)   { key :return }

    rule(:THEN)     { key :then }

    rule(:UNLESS)   { key :unless }

    rule(:WHILE)    { key :while }

    rule(:UNTIL)    { key :until }

    rule(:NEW)      { key :new }

    rule(:CLASS)    { key :class }

    rule(:SWITCH)   { key :switch }

    rule(:WHEN)     { key :when }

    rule(:TRY)      { key :try }

    rule(:CATCH)    { key :catch }

    rule(:EXTENDS)  { key :extends }

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
    rule(:MUL) { trim(match['\*/%'] >> str("=").absent?) }

    # Addition and subtraction
    rule(:ADD) { trim(match['\+\-'] >> str("=").absent?) }

    # Bitwise left shift and right shift
    rule(:SHIFT) { trim(str("<<") | str(">>")) }

    # For relational operators <, ≤ > and ≥ respectively
    rule(:COMPARE) { trim(str("<=") | str(">=") | match['<>'] >> str("=").absent?) }

    # For relational operators = and ≠ respectively
    rule(:EQ) { trim(str("==") | str("!=") | key("is") | key("isnt")) }

    # Bitwise AND
    rule(:BAND) { trim(str("&") >> str("=").absent?) }

    # Bitwise XOR
    rule(:BXOR) { trim(str("^") >> str("=").absent?) }

    # Bitwise OR
    rule(:BOR) { trim(str("|") >> str("=").absent?) }

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
