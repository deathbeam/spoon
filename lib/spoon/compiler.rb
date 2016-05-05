module Spoon
  class Compiler
    def initialize
      @nodes = {
        :root => Root,
        :op => Operation,
        :call => Call,
        :import => Import,
        :value => Value
      }
    end

    def compile(node, parent = nil)
      @nodes[node.type].new(self, node, parent).compile.to_s
    end
  end

  class Base
    def initialize(compiler, node, parent)
      @compiler = compiler
      @node = node
      @parent = parent
      @content = ""
    end

    def compile
      @content = ""
    end

    def compile_next(node)
      @compiler.compile(node, self)
    end
  end

  class Root < Base
    def compile
      super
      imports = ""
      @content << "class Main {\n"
      @content << "static public function main() {\n"

      @node.children.each do |child|
        if child.type == :import
          imports << compile_next(child) << ";\n"
        else
          @content << compile_next(child) << ";\n"
        end
      end

      @content = "#{imports}\n#{@content}"
      @content << "}\n"
      @content << "}"
    end
  end

  class Operation < Base
    def compile
      super
      children = @node.children.dup
      operator = children.shift.to_s

      case @node.option :operation
      when :infix
        @content << compile_next(children.shift)
        @content << " #{operator} "
        @content << compile_next(children.shift)
      when :prefix
        @content << operator
        @content << compile_next(children.shift)
      when :suffix
        @content << compile_next(children.shift)
        @content << operator
      end
    end
  end

  class Value < Base
    def compile
      super
      @content << @node.children.dup.shift.to_s
    end
  end

  class Call < Base
    def compile
      super
      children = @node.children.dup
      @content << children.shift.to_s
      @content << "("

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless children.last == child
      end

      @content << ")"
    end
  end

  class Import < Base
    def compile
      super
      children = @node.children.dup

      @content << "import "

      children.each do |child|
        @content << compile_next(child)
        @content << "." unless children.last == child
      end

      @content
    end
  end
end
