require "parslet"
require 'parslet/convenience'

module Spoon
  class Parslet::Parser
    rule(:space)  { (match("\s") | match("\n")).repeat(1) }
    rule(:space?) { space.maybe }
    rule(:name)   { space? >> skip_kwd >> match["a-z"].repeat(1).as(:name) >> space? }
    rule(:number) { match["0-9"].repeat(1).as(:number) >> space? }
    rule(:lbrace) { key("{") }
    rule(:rbrace) { key("}") }
    rule(:lparen) { key("(") }
    rule(:rparen) { key(")") }
    rule(:comma)  { key(",") }

    rule(:def_kwd)  { key("def") }
    rule(:do_kwd)   { key("do") }
    rule(:end_kwd)  { key("end") }
    rule(:skip_kwd) { def_kwd.absent? >> do_kwd.absent? >> end_kwd.absent? }

    def key(value)
      space? >> str(value) >> space?
    end
  end

  class Parser < Parslet::Parser
    root :script

    rule(:script)   { space? >> expressions >> space? }

    rule(:expressions?)  { expressions.maybe }
    rule(:expressions)   { expression.repeat(1) }
    rule(:expression)    { name | number | comment | function }


    rule(:function)      { def_kwd >> name.as(:function) >> params.maybe >> body }
    rule(:params)        { lparen >> ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >> rparen}
    rule(:body)          { do_kwd >> expressions?.as(:body) | expressions?.as(:body) >> end_kwd }

    rule(:comment)       { (comment_block | comment_line).as(:comment) }
    rule(:comment_block) { key("###") >> match["^###"].repeat.as(:text) >> key("###") }
    rule(:comment_line)  { key("#") >> match["^\n"].repeat.as(:text) }
  end
end
