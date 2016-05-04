module Spoon
  class Compiler
    def initialize
      @nodes = {
        :root => Root.new(self),
        :value => Value.new(self),
        :op => Operation.new(self)
      }
    end

    def compile(node)
      @nodes[node.type].compile node
    end
  end

  class Base
    def initialize(compiler)
      @compiler = compiler
    end

    def compile(node)
      @content = ""
    end
  end

  class Root < Base
    def compile(node)
      super
      @content << "class Main {\n"
      @content << "static public function main() {\n"

      node.children.each do |child|
        @content << @compiler.compile(child).to_s << ";\n"
      end

      @content << "}\n"
      @content << "}"
    end
  end

  class Operation < Base
    def compile(node)
      super
      children = node.children.dup
      operator = children.shift.to_s

      case node.option :operation
      when :infix
        @content << @compiler.compile(children.shift)
        @content << " #{operator} "
        @content << @compiler.compile(children.shift)
      when :prefix
        @content << operator.to_s
        @content << @compiler.compile(children.shift)
      when :suffix
        @content << @compiler.compile(children.shift)
        @content << operator.to_s
      end
    end
  end

  class Value < Base
    def compile(node)
      super
      @content << node.children.dup.shift.to_s
    end
  end
end
