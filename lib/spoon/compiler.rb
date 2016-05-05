module Spoon
  class Compiler
    def initialize
      @nodes = {
        :root => Root,
        :block => Block,
        :function => Function,
        :op => Operation,
        :call => Call,
        :import => Import,
        :param => Param,
        :value => Value
      }
    end

    def compile(node, parent = nil, tab = "")
      @nodes[node.type].new(self, node, parent, tab).compile.to_s
    end
  end

  class Base
    def initialize(compiler, node, parent, tab)
      @compiler = compiler
      @node = node
      @parent = parent
      @content = ""
      @tab = tab
    end

    def compile
      @content
    end

    def compile_next(node)
      @compiler.compile(node, @node, @tab + "  ")
    end
  end

  class Root < Base
    def initialize(compiler, node, parent, tab)
      super
      @tab = "    "
    end

    def compile
      imports = ""
      @content << "class Main {\n"
      @content << "  static public function main() {\n"

      @node.children.each do |child|
        if child.type == :import
          imports << compile_next(child) << ";\n"
        else
          @content << @tab << compile_next(child) << ";\n"
        end
      end

      @content = "#{imports}\n#{@content}"
      @content << "  }\n"
      @content << "}"

      super
    end
  end

  class Block < Base
    def compile
      @node.children.each do |child|
        @content << @tab << compile_next(child) << ";\n"
      end

      super
    end
  end

  class Operation < Base
    def compile
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

      super
    end
  end

  class Value < Base
    def compile
      @content << @node.children.dup.shift.to_s
      super
    end
  end

  class Param < Base
    def compile
      children = @node.children.dup
      @content << children.shift.to_s
      @content << " = " << compile_next(children.shift) unless children.empty?
      super
    end
  end

  class Call < Base
    def compile
      children = @node.children.dup
      @content << children.shift.to_s
      @content << "("

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless children.last == child
      end

      @content << ")"
      super
    end
  end

  class Import < Base
    def compile
      children = @node.children.dup

      @content << "import "

      children.each do |child|
        @content << compile_next(child)
        @content << "." unless children.last == child
      end

      super
    end
  end

  class Function < Base
    def compile
      children = @node.children.dup
      name = children.shift.to_s

      @content << "function #{name}("

      if children.length > 1
        children.each do |child|
          unless child == children.last
            @content << compile_next(child)
            @content << ", " unless child == children[children.length - 2]
          end
        end
      end

      @content << ") {\n"
      @content << compile_next(children.last)
      @content << @tab << "}"
    end
  end
end
