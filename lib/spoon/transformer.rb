require "ast/node"
require "parslet"
require "spoon/util/ast_extensions"

module Spoon
  class Transformer < Parslet::Transform
    rule(:root => sequence(:expressions)) {
      AST::Node.new :root, expressions
    }

    rule(:block => simple(:expressions)) {
      AST::Node.new :block, [ expressions ]
    }

    rule(:block => sequence(:expressions)) {
      AST::Node.new :block, expressions
    }

    rule(:boolean => simple(:boolean)) {
      AST::Node.new :value, [ boolean.to_b ]
    }

    rule(:string => simple(:string)) {
      AST::Node.new :value, [ "'#{string}'" ]
    }

    rule(:number => simple(:number)) {
      AST::Node.new :value, [ number.to_i ]
    }

    rule(:identifier => simple(:identifier)) {
      AST::Node.new :value, [ identifier.to_v ]
    }

    rule(:arg => simple(:arg)) {
      AST::Node.new :arg, [ arg ]
    }

    rule(:param => { :name => simple(:name) }) {
      AST::Node.new :param, [ name.to_v ]
    }

    rule(:param => { :name => simple(:name), :value => simple(:value) }) {
      AST::Node.new :param, [ name.to_v, value]
    }

    rule(:left => simple(:left), :op => simple(:op), :right => simple(:right)) {
      AST::Node.new :op, [ op.trim, left, right ]
    }

    rule(:left => simple(:left), :op => simple(:op)) {
      AST::Node.new :op, [ op.trim, left ]
    }

    rule(:op => simple(:op), :right => simple(:right)) {
      AST::Node.new :op, [ op.trim, right ]
    }

    rule(:call => { :name => simple(:name) }) {
      AST::Node.new :call, [ name.to_v ]
    }

    rule(:call => {
          :name => simple(:name),
          :args => simple(:args)
          }) {
      AST::Node.new :call, [ name.to_v, args ]
    }

    rule(:call => {
          :name => simple(:name),
          :args => sequence(:args)
          }) {
      AST::Node.new :call, [ name.to_v ] + args
    }

    rule(:closure => {
          :body => simple(:body)
          }) {
      AST::Node.new :closure, [ body ]
    }

    rule(:closure => {
          :params => simple(:params),
          :body => simple(:body)
          }) {
      AST::Node.new :closure, [ params, body ]
    }

    rule(:closure => {
          :params => sequence(:params),
          :body => simple(:body)
          }) {
      AST::Node.new :closure, params + [ body ]
    }

    rule(:function => {
          :name => simple(:name),
          :body => simple(:body)
          }) {
      AST::Node.new :function, [ name.to_v, body ]
    }

    rule(:function => {
          :name => simple(:name),
          :params => simple(:params),
          :body => simple(:body)
          }) {
      AST::Node.new :function, [ name.to_v , params, body ]
    }

    rule(:function => {
          :name => simple(:name),
          :params => sequence(:params),
          :body => simple(:body)
          }) {
      AST::Node.new :function, [ name.to_v ] + params + [ body ]
    }

    rule(:if => {
          :condition => simple(:condition),
          :true => simple(:if_true)
          }) {
      AST::Node.new :if, [ condition, if_true ]
    }

    rule(:if => {
          :condition => simple(:condition),
          :true => simple(:if_true),
          :false => simple(:if_false)
          }) {
      AST::Node.new :if, [ condition, if_true, if_false ]
    }

    rule(:unless => {
          :condition => simple(:condition),
          :true => simple(:if_true)
          }) {
      AST::Node.new :if, [ AST::Node.new(:op, [ "!", condition ]), if_true ]
    }

    rule(:unless => {
          :condition => simple(:condition),
          :true => simple(:if_true),
          :false => simple(:if_false)
          }) {
      AST::Node.new :if, [ AST::Node.new(:op, [ "!", condition ]), if_true, if_false ]
    }

    rule(:for => {
          :condition => simple(:condition),
          :body => simple(:body)
          }) {
      AST::Node.new :for, [ condition, body ]
    }

    rule(:while => {
          :condition => simple(:condition),
          :body => simple(:body)
          }) {
      AST::Node.new :while, [ condition, body ]
    }
  end
end
