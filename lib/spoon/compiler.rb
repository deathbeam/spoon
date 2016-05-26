require "spoon/util/namespace"

module Spoon
  class Compiler
    attr_reader :name
    attr_reader :scope
    attr_reader :static_scope
    attr_reader :instance_scope
    attr_reader :class_names

    def initialize(path = "main")
      @name = File.basename(path, ".*").split('_').collect!{ |w| w.capitalize }.join
      @class_names = []
      @scope = Spoon::Util::Namespace.new
      @static_scope = Spoon::Util::Namespace.new
      @instance_scope = Spoon::Util::Namespace.new

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
        :hash => Haash,
        :access => Access,
        :class => Class,
        :annotation => Annotation
      }
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

    def subtree(node)
      @compiler.compile(node, self, @tab)
    end

    def string(str)
      if str.start_with? "'"
        str.gsub!("\\#", "#") || str
      else
        str_array = str.split('-')
        first = str_array.shift
        first + str_array.collect(&:capitalize).join
      end
    end

    def each(children, separator)
      content = ""

      children.each do |child|
        content << subtree(child)
        content << separator unless child.equal? children.last
      end

      content
    end

    def cache
      result = ""

      @compiler.static_scope.get.each do |key, value|
        if value
          result << "  static public var #{key}"
          result << " : #{value}" if value.is_a?(String)
          result << eol
        end
      end

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

    def push_scope(name)
      @compiler.scope.add
      @compiler.scope.push name
      @compiler.class_names.push name
      @compiler.static_scope.add
      @compiler.instance_scope.add
    end

    def pop_scope
      @compiler.scope.pop
      @compiler.static_scope.pop
      @compiler.instance_scope.pop
      @compiler.class_names.pop
    end

    def compile
      imports = ""
      classes = ""
      import_calls = ""
      push_scope @compiler.name

      @node.children.each do |child|
        if child.type == :import
          imports << subtree(child) + eol(child)
          last = child.children.last

          if last.option :is_type
            name = subtree(child.children.last)
            import_calls << "#{@tab}if (Reflect.hasField(#{name}, 'main')) Reflect.callMethod(#{name}, Reflect.field(#{name}, 'main'), [])#{eol(child.children.last)}"
          end
        elsif child.type == :class
          classes << subtree(child) + eol(child)
        else
          @content << @tab + subtree(child) + eol(child)
        end
      end

      @content = "class #{@compiler.name} {\n#{cache}  @:keep public static function main() {\n#{import_calls}#{@content}"
      @content = "#{imports}#{@content}"
      @content << "  }\n"
      @content << "}\n#{classes}"
      pop_scope

      super
    end
  end

  class Class < Root
    def initialize(compiler, node, parent, tab)
      super
      @tab = ""
    end

    def compile
      children = @node.children.dup
      name = subtree(children.shift)
      push_scope name

      @content << "class #{name} "
      @content << "extends #{subtree(children.shift)} " if @node.option :is_extended
      @content << subtree(children.shift)

      pop_scope
      @content
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
        content << @tab << subtree(child) << eol(child)
      end

      @content << "{\n"
      @content << "#{cache}" if @parent.node.type == :class
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
            @content << "var #{assign_name} #{operator} #{subtree(right)}#{eol(right)}"
            @@assign_counter += 1

            left.children.each_with_index do |child, index|
              @content << @parent.tab
              @content << scope_name(child)
              @content << " #{operator} #{assign_name}[#{index}]"
              @content << eol(child) unless child.equal? left.children.last
            end
          elsif left.type == :map
            assign_name = "__assign#{@@assign_counter}"
            @content << "var #{assign_name} #{operator} #{subtree(right)}#{eol(right)}"
            @@assign_counter += 1

            left.children.each do |child|
              child_children = child.children.dup
              child_children.shift
              child_name = subtree(child_children.shift)
              child_alias_node = child_children.shift
              @content << @parent.tab
              @content << scope_name(child_alias_node)
              @content << " #{operator} #{assign_name}.#{child_name}"
              @content << eol(child) unless child.equal? left.children.last
            end
          elsif @parent.parent != nil && @parent.parent.node.type == :class
            is_this = left.option :is_this
            name = ""

            if is_this
              name = subtree(left.children.first)
              @compiler.static_scope.push name, false
            else
              name = subtree(left)
              @compiler.instance_scope.push name, false
            end

            value = subtree(right)

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
            @content << subtree(right)
          end
        else
          @content << subtree(left)
          @content << " " unless @node.option :is_chain
          @content << operator
          @content << " " unless @node.option :is_chain
          @content << subtree(right)
        end
      when :prefix
        @content << operator
        @content << subtree(children.shift)
      when :suffix
        @content << subtree(children.shift)
        @content << operator
      end

      @content << ")" if @parent.node.type == :op && !@parent.node.option(:is_assign)

      super
    end

    def scope_name(node)
      content = subtree(node)
      is_self = node.option :is_self
      is_this = node.option :is_this

      if is_self || is_this
        child = node.children.first
        name = ""
        type = true

        if child.option :is_typed
          children = child.children.dup
          name = subtree(children.shift)
          type = subtree(children.shift)
        else
          name = subtree(child)
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
        name = subtree(children.shift)
        type = subtree(children.shift)
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
          @content << string(child.to_s)
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
            @content << subtree(child)
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

      @content << subtree(children.shift)
      @content << " : #{subtree(type)}" if type
      @content << " = #{subtree(children.shift)}" unless children.empty?
      super
    end
  end

  class Annotation < Base
    def compile
      body = subtree(@node.children.first)
      @content << "@" unless body == "override"
      @content << body
    end
  end

  class Access < Base
    def compile
      children = @node.children.dup
      @content << "#{subtree(children.shift)}[#{subtree(children.shift)}]"
      super
    end
  end

  class Array < Base
    def compile
      @content << "["
      @content << each(@node.children, ", ")
      @content << "]"
      super
    end
  end

  class Haash < Base
    def compile
      @content << "{"
      @content << each(@node.children, ", ")
      @content << "}"
      super
    end
  end

  class Call < Base
    def compile
      children = @node.children.dup
      @content << subtree(children.shift)
      @content << "("
      @content << each(children, ", ")
      @content << ")"
      super
    end
  end

  class New < Call
    def compile
      @content << "new "
      super
    end
  end

  class Import < Base
    def compile
      @content << "import "
      @content << each(@node.children, ".")
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
            @content << subtree(child)
            @content << ", " unless child.equal? children[children.length - 2]
          end
        end
      end

      @content << ") "
      @content << ": #{subtree(type)} " if type
      @content << "return " unless @node.option :fat
      @content << subtree(children.last)

      @compiler.scope.pop
      super
    end
  end

  class If < Base
    def compile
      children = @node.children.dup

      @content << "if (#{subtree(children.shift)}) "
      @content << subtree(children.shift)
      @content << " else #{subtree(children.shift)}" unless children.empty?
      super
    end
  end

  class For < Base
    @@for_counter = 0

    def compile
      children = @node.children.dup
      left = children.shift
      right = children.shift
      left_children = left.children.dup
      left_children.shift
      left_children_children = left_children.shift.children.dup
      content = "for ("

      if left_children_children.shift == ","
        for_name = "__for#{@@for_counter}"
        @@for_counter += 1
        key_name = subtree(left_children_children.shift)
        value_name = subtree(left_children_children.shift)

        content << "#{key_name} in Reflect.fields(#{for_name})"
        content = "var #{for_name} = #{subtree(left_children.shift)}#{eol(left)}#{@tab}" + content
        value = AST::Node.new :value, [ "var #{value_name} = Reflect.field(#{for_name}, #{key_name})" ]

        if right.type == :block
          right = AST::Node.new :block, [ value ] + right.children.dup
        else
          right = AST::Node.new :block, [ value, right ]
        end
      else
        content << subtree(left)
      end

      content <<  ") "
      content << subtree(right)
      @content << content
      super
    end
  end

  class While < Base
    def compile
      children = @node.children.dup

      @content << "while (#{subtree(children.shift)}) "
      @content << subtree(children.shift)
      super
    end
  end

  class Return < Base
    def compile
      @content << "return"
      @content << " #{subtree(@node.children.first)}" unless @node.children.empty?
      super
    end
  end
end
