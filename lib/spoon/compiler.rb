require "spoon/util/namespace"

module Spoon
  class Compiler
    attr_reader :name
    attr_reader :scope
    attr_reader :static_scope
    attr_reader :instance_scope
    attr_reader :class_names

    def initialize(path = "main")
      basename = File.basename(path, ".*")
      @name = basename.split('_').collect!{ |w| w.capitalize }.join
      @class_names = []

      @nodes = {
        :root => Root,
        :block => Block,
        :closure => Closure,
        :if => If,
        :for => For,
        :while => While,
        :op => Operation,
        :call => Call,
        :new => New,
        :return => Return,
        :import => Import,
        :param => Param,
        :value => Value,
        :array => Array,
        :map => Map,
        :access => Access,
        :class => Class,
        :annotation => Annotation
      }

      @scope = Spoon::Util::Namespace.new
      @static_scope = Spoon::Util::Namespace.new
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
        str.gsub!("\\#", "#") || str
      else
        str_array = str.split('-')
        first = str_array.shift
        first + str_array.collect(&:capitalize).join
      end
    end

    def compile_class_variables
      result = ""

      @compiler.static_scope.get.each do |key, value|
        if value
          result << "  static public var #{key}"
          result << " : #{value}" if value.is_a?(String)
          result << eol
        end
      end

      result
    end

    def compile_instance_variables
      result = ""

      @compiler.instance_scope.get.each do |key, value|
        if value
          result << "  public var #{key}"
          result << " : #{value}" if value.is_a?(String)
          result << eol
        end
      end

      result
    end

    def eol(node = nil)
      (node == nil || (node.type != :annotation && node.type != :class)) ? ";\n" : "\n"
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
      @compiler.static_scope.add
      @compiler.instance_scope.add

      imports = ""
      classes = ""
      import_calls = ""

      @node.children.each do |child|
        if child.type == :import
          imports << compile_next(child) << eol(child)
          last = child.children.last

          if last.option :is_type
            name = compile_next(child.children.last)
            import_calls << "#{@tab}if (Reflect.hasField(#{name}, 'main')) Reflect.callMethod(#{name}, Reflect.field(#{name}, 'main'), [])#{eol(child.children.last)}"
          end
        elsif child.type == :class
          classes << compile_next(child) << eol(child)
        else
          @content << @tab << compile_next(child) << eol(child)
        end
      end

      @content = "class #{@compiler.name} {\n#{compile_class_variables}#{compile_instance_variables}  @:keep public static function main() {\n#{import_calls}#{@content}"
      @content = "#{imports}#{@content}"
      @content << "  }\n"
      @content << "}\n#{classes}"

      @compiler.scope.pop
      @compiler.static_scope.pop
      @compiler.instance_scope.pop
      @compiler.class_names.pop
      super
    end
  end

  class Class < Base
    def initialize(compiler, node, parent, tab)
      super
      @tab = ""
    end

    def compile
      children = @node.children.dup
      name = compile_next(children.shift)

      @compiler.scope.add
      @compiler.scope.push name
      @compiler.class_names.push name
      @compiler.static_scope.add
      @compiler.instance_scope.add

      @content << "class #{name} "
      @content << "extends #{compile_next(children.shift)} " if @node.option :is_extended

      body = children.shift
      @content << compile_next(body)

      @compiler.scope.pop
      @compiler.static_scope.pop
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
      content = ""

      @node.children.each do |child|
        content << @tab << compile_next(child) << eol(child)
      end

      @content << "{\n"
      (@content << "#{compile_class_variables}#{compile_instance_variables}") if @parent.node.type == :class
      @content << content

      @content << @parent.tab << "}"
      super
    end
  end

  class Operation < Base
    @@assign_counter = 0

    def compile
      children = @node.children.dup
      operator = children.shift.to_s

      @content << "(" if @parent.node.type == :op && !@parent.node.option(:is_assign)

      case @node.option :operation
      when :infix
        left = children.shift
        right = children.shift

        if @node.option :is_assign
          if left.type == :array
            assign_name = "__assign#{@@assign_counter}"
            @content << "var #{assign_name} #{operator} #{compile_next(right)}#{eol(right)}"
            @@assign_counter += 1

            left.children.each_with_index do |child, index|
              child_name = compile_next(child)
              @content << @parent.tab
              scope_name(child)
              @content << "#{child_name} #{operator} #{assign_name}[#{index}]"
              @content << eol(child) unless child.equal? left.children.last
            end
          elsif left.type == :map
            assign_name = "__assign#{@@assign_counter}"
            @content << "var #{assign_name} #{operator} #{compile_next(right)}#{eol(right)}"
            @@assign_counter += 1

            left.children.each do |child|
              child_children = child.children.dup
              child_children.shift
              child_alias_node = child_children.shift
              child_alias = compile_next(child_alias_node)
              child_name = compile_next(child_children.shift)
              @content << @parent.tab
              scope_name(child_alias_node)
              @content << "#{child_alias} #{operator} #{assign_name}.#{child_name}"
              @content << eol(child) unless child.equal? left.children.last
            end
          elsif @parent.parent != nil && @parent.parent.node.type == :class
            is_this = left.option :is_this
            name = ""

            if is_this
              name = compile_next(left.children.first)
              @compiler.static_scope.push name, false
            else
              name = compile_next(left)
              @compiler.instance_scope.push name, false
            end

            value = compile_next(right)

            if right.type == :closure
              value[8] = " #{name}"
            else
              value = "var #{name} #{operator} #{value}"
            end

            value = "static #{value}" if is_this
            @content << "public #{value}"
          else
            @content << scope_name(left)
            @content << " " unless @node.option :is_chain
            @content << operator
            @content << " " unless @node.option :is_chain
            @content << compile_next(right)
          end
        else
          @content << compile_next(left)
          @content << " " unless @node.option :is_chain
          @content << operator
          @content << " " unless @node.option :is_chain
          @content << compile_next(right)
        end
      when :prefix
        @content << operator
        @content << compile_next(children.shift)
      when :suffix
        @content << compile_next(children.shift)
        @content << operator
      end

      @content << ")" if @parent.node.type == :op && !@parent.node.option(:is_assign)

      super
    end

    def scope_name(node)
      content = compile_next(node)
      is_self = node.option :is_self
      is_this = node.option :is_this

      if is_self || is_this
        child = node.children.first
        name = ""
        type = true

        if child.option :is_typed
          children = child.children.dup
          name = compile_next(children.shift)
          type = compile_next(children.shift)
        else
          name = compile_next(child)
        end

        if is_self
          raise ArgumentError, 'Self call cannot be used outside of class' unless @compiler.in_class
          @compiler.static_scope.push name, type
        elsif is_this
          if @compiler.in_class
            @compiler.instance_scope.push name, type
          else
            @compiler.static_scope.push name, type
          end
        end
      elsif node.option :is_typed
        children = node.children.dup
        name = compile_next(children.shift)
        type = compile_next(children.shift)
        content = "var " << content if @compiler.scope.push name, type
      elsif node.type == :value
        content = "var " << content if @compiler.scope.push content
      end

      content
    end
  end

  class Value < Base
    def compile
      children = @node.children.dup

      children.each do |child|
        if child.is_a?(String) || child.is_a?(Fixnum) || [true, false].include?(child)
          @content << compile_str(child.to_s)
        else
          if @node.option :is_self
            raise ArgumentError, 'Self call cannot be used outside of class' unless @compiler.in_class
            @content << "#{@compiler.class_names.last}."
          elsif @node.option :is_this
            @content << (@compiler.in_class ?  "this." : "#{@compiler.class_names.last}.")
          end

          unless child.equal?(children.last) &&
                  @node.option(:is_typed) &&
                  (@parent.node.option(:is_self) ||
                  @parent.node.option(:is_this))
            @content << compile_next(child)
          end
        end

        unless child.equal? children.last
          if @node.option(:is_typed)
            if !@parent.node.option(:is_self) && !@parent.node.option(:is_this)
              @content << " : "
            end
          else
            @content << " + "
          end
        end
      end

      super
    end
  end

  class Param < Base
    def compile
      children = @node.children.dup
      type = (@node.option(:is_typed) ? children.shift : false)

      @content << compile_next(children.shift)
      @content << " : #{compile_next(type)}" if type
      @content << " = " << compile_next(children.shift) unless children.empty?
      super
    end
  end

  class Annotation < Base
    def compile
      children = @node.children.dup
      body = compile_next(children.shift)
      @content << "@" unless body == "override"
      @content << body
    end
  end

  class Access < Base
    def compile
      children = @node.children.dup
      @content << compile_next(children.shift)
      @content << "["
      @content << compile_next(children.shift)
      @content << "]"
      super
    end
  end

  class Array < Base
    def compile
      children = @node.children.dup
      @content << "["

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless child.equal? children.last
      end

      @content << "]"
      super
    end
  end

  class Map < Base
    def compile
      children = @node.children.dup
      @content << "{"

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless child.equal? children.last
      end

      @content << "}"
      super
    end
  end

  class New < Base
    def compile
      children = @node.children.dup
      @content << "new "
      @content << compile_next(children.shift)
      @content << "("

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless child.equal? children.last
      end

      @content << ")"
      super
    end
  end

  class Call < Base
    def compile
      children = @node.children.dup
      @content << compile_next(children.shift)
      @content << "("

      children.each do |child|
        @content << compile_next(child)
        @content << ", " unless child.equal? children.last
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
        @content << "." unless child.equal? children.last
      end

      super
    end
  end

  class Closure < Base
    def compile
      @compiler.scope.add

      children = @node.children.dup
      type = (@node.option(:is_typed) ? children.shift : false)

      @content << "function ("

      if children.length > 1
        children.each do |child|
          name = child.children.first.to_s
          @compiler.scope.push name

          unless child.equal? children.last
            @content << compile_next(child)
            @content << ", " unless child == children[children.length - 2]
          end
        end
      end

      @content << ") "
      @content << ": #{compile_next(type)} " if type
      @content << "return " unless @node.option :fat
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
      @content << "return "
      @content << compile_next(@node.children.dup.shift)
      super
    end
  end
end
