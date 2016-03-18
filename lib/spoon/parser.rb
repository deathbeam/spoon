require "parslet"
require "parslet/convenience"

require "spoon/util/indentparser"

module Spoon
  class Parser < Spoon::Util::IndentParser
    def key(value)
      @keys = [] if @keys.nil?
      @keys.push value unless @keys.include? value

      sym(value)
    end

    def sym(value)
      str(value) >> space?
    end

    rule(:skip_key) {
      if @keys.nil? or @keys.empty?
        alwaysmatch
      else
        result = str(@keys.first).absent?

        for keyword in @keys
          result >> str(keyword).absent?
        end

        result
      end
    }

    rule(:newline)     { (match("\n") | match("\r")).repeat(1) }
    rule(:newline?)    { newline.maybe }
    rule(:space)       { (match("\s") | comment).repeat(1) }
    rule(:space?)      { space.maybe }
    rule(:whitespace)  { (match("\s") | match("\n") | match("\r")).repeat(1) }
    rule(:whitespace?) { whitespace.maybe }
    rule(:stop)        { match["^\n"].repeat }
    rule(:comment)     { str("#") >> stop.as(:comment) }

    rule(:name)   { skip_key >> match["a-z"].repeat(1).as(:name) >> space?}
    rule(:number) { match["0-9"].repeat(1).as(:number) }

    rule(:expressions?)  { expressions.maybe }
    rule(:expressions)   { expression.repeat(1) }
    rule(:expression)    { function | name | number | comment }

    rule(:block) {
      newline? >> indent >>
        (expression >>
          (newline? >> samedent >> expression).repeat).maybe.as(:block) >>
      dedent
    }

    rule(:function) {
      key("def") >> name.as(:function) >> params.maybe >> (block | whitespace? >> expression).as(:body)
    }


    rule(:params) {
      sym("(") >> (name >> (sym(",") >> name).repeat(0)).maybe.as(:params) >> str(")")
    }

=begin
    rule(:els) {
      else_kwd >> condition_body.as(:else)
    }

    rule(:elses) {
      (else_kwd >> if_kwd >> lparen >> expression.as(:condition) >> rparen >>
        condition_body.as(:if)).repeat.as(:else)
    }

    rule(:condition) {
      if_kwd >> lparen >> expression.as(:condition) >> rparen >>
          condition_body.maybe.as(:if) >>
        elses.maybe.as(:elses) >>
        els.maybe
    }

    rule(:condition_body) { do_kwd >> expressions?.as(:body) | expressions?.as(:body) >> (else_kwd.present? | end_kwd) }
=end

    root :script
    rule(:script) { whitespace? >> expressions >> whitespace? }
  end
end
