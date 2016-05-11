require "spoon/util/namespace"

module Spoon
  class Compiler
    attr_reader :name
    attr_reader :scope
    attr_reader :class_scope
    attr_reader :instance_scope
    attr_reader :class_names

    def initialize(path = "main")
      basename = File.basename(path, ".*")
      @name = basename.split('_').collect!{ |w| w.capitalize }.join
      @class_names = []

      @nodes = {
        :root => Root,
        :block => Block,
        :function => Function,
        :closure => Closure,
        :if => If,
        :for => For,
        :while => While,
        :op => Operation,
        :call => Call,
        :return => Return,
        :import => Import,
        :param => Param,
        :self => Self,
        :this => This,
        :value => Value
      }

      @scope = Spoon::Util::Namespace.new
      @class_scope = Spoon::Util::Namespace.new
      @instance_scope = Spoon::Util::Namespace.new
    end

    def in_class
      @class_names.length > 1
    end

    def compile(node, parent = nil, tab = "")
      @nodes[node.type].new(self, node, parent, tab).compile.to_s
    end
  end

  class Base
    attr_reader :tab
    attr_reader :node
    attr_reader :parent

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
      @compiler.compile(node, self, @tab)
    end

    def compile_str(str)
      if str.start_with? "'"
        str
      else
        str.gsub!("-", "_") || str
      end
    end
  end

  class Root < Base
    def initialize(compiler, node, parent, tab)
      super
      @tab = "    "
    end

    def compile
      @compiler.scope.add
      @compiler.scope.push @compiler.name
      @compiler.class_names.push @compiler.name
      @compiler.class_scope.add
      @compiler.instance_scope.add

      imports = ""

      @node.children.each do |child|
        if child.type == :import
          imports << compile_next(child) << ";\n"
        else
          @content << @tab << compile_next(child) << ";\n"
        end
      end

      class_variables = ""

      @compiler.class_scope.get.each do |key, value|
        class_variables << "  static var #{key};\n"
      end

      instance_variables = ""

      @compiler.instance_scope.get.each do |key, value|
        class_variables << "  var #{key};\n"
      end

      @content = "class #{@compiler.name} {\n#{class_variables}#{instance_variables}  static public function main() {\n#{@content}"
      @content = "#{imports}#{@content}"
      @content << "  }\n"
      @content << "}"

      @compiler.scope.pop
      @compiler.class_scope.pop
      @compiler.instance_scope.pop
      @compiler.class_names.pop
      super
    end
  end

  class Block < Base
    def initialize(compiler, node, parent, tab)
      super
      @tab = tab + "  "
    end

    def compile
      @content << "{\n"

      @node.children.each do |child|
        @content << @tab << compile_next(child) << ";\n"
      end

      @content << @parent.tab << "}"
      super
    end
  end

  class Operation < Base
    def compile
      children = @node.children.dup
      operator = children.shift.to_s

      @content << "(" if @parent.node.type == :op

      case @node.option :operation
      when :infix
        left = children.shift
        content = compile_next(left)

        if operator == "="
          if left.type == :value
            if @compiler.scope.push content
              @content << "var "
            end
          elsif left.type == :self || left.type == :this
            name = compile_next(left.children.first)

            if left.type == :self
              raise ArgumentError, 'Self call cannot be used outside of class' unless @compiler.in_class
              @compiler.class_scope.push name
            elsif left.type == :this
              if @compiler.in_class
                @compiler.instance_scope.push name
              else
                @compiler.class_scope.push name
              end
            end
          end
        end

        @content << content
        @content << " #{operator} "
        @content << compile_next(children.shift)
      when :prefix
        @content << operator
        @content << compile_next(children.shift)
      when :suffix
        @content << compile_next(children.shift)
        @content << operator
      end

      @content << ")" if @parent.node.type == :op

      super
    end
  end

  class This < Base
    def compile
      child = @node.children.dup.shift
      @content << (@compiler.in_class ?  "this." : "#{@compiler.class_names.last}.")
      @content << compile_next(child)
      super
    end
  end

  class Self < Base
    def compile
      raise ArgumentError, 'Self call cannot be used outside of class' unless @compiler.in_class
      child = @node.children.dup.shift
      @content << "#{@compiler.class_names.last}."
      @content << compile_next(child)
      super
    end
  end

  class Value < Base
    def compile
      children = @node.children.dup

      children.each do |child|
        if child.is_a?(String) || child.is_a?(Fixnum) || [true, false].include?(child)
          @content << compile_str(child.to_s)
        else
          @content << compile_next(child)
        end

        @content << " + " unless children.last == child
      end

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
      @content << compile_str(children.shift.to_s)
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
      @compiler.scope.add

      children = @node.children.dup
      first = children.shift

      if first.is_a?(String) || first.is_a?(Fixnum) || [true, false].include?(first)
        name = compile_str(first.to_s)
        @content << "function #{name}("
      elsif first.type == :self
        name = compile_next(first.children.first)
        @content << "static function #{name}("
      end

      if children.length > 1
        children.each do |child|
          name = child.children.first.to_s
          @compiler.scope.push name

          unless child == children.last
            @content << compile_next(child)
            @content << ", " unless child == children[children.length - 2]
          end
        end
      end

      @content << ") "
      @content << compile_next(children.last)

      @compiler.scope.pop
      super
    end
  end

  class Closure < Base
    def compile
      @compiler.scope.add

      children = @node.children.dup

      @content << "function ("

      if children.length > 1
        children.each do |child|
          name = child.children.first.to_s
          @compiler.scope.push name

          unless child == children.last
            @content << compile_next(child)
            @content << ", " unless child == children[children.length - 2]
          end
        end
      end

      @content << ") return "
      @content << compile_next(children.last)

      @compiler.scope.pop
      super
    end
  end

  class If < Base
    def compile
      children = @node.children.dup

      @content << "if (" << compile_next(children.shift) << ") "
      @content << compile_next(children.shift)
      @content << " else " << compile_next(children.shift) unless children.empty?
      super
    end
  end

  class For < Base
    def compile
      children = @node.children.dup

      @content << "for (" << compile_next(children.shift) << ") "
      @content << compile_next(children.shift)
      super
    end
  end

  class While < Base
    def compile
      children = @node.children.dup

      @content << "while (" << compile_next(children.shift) << ") "
      @content << compile_next(children.shift)
      super
    end
  end

  class Return < Base
    def compile
      children = @node.children.dup
      multi = children.length > 1
      @content << "return "
      @content << "[" if multi

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless children.last == child
      end

      @content << "]" if multi

      super
    end
  end
end
