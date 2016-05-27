require "colorize"
require "thor"
require "pp"

require "spoon/compiler"
require "spoon/parser"
require "spoon/transformer"
require "spoon/version"

module Spoon
  BANNER = %{
.d8888. d8888b.  .d88b.   .d88b.  d8b   db
88'  YP 88  `8D .8P  Y8. .8P  Y8. 888o  88
`8bo.   88oodD' 88    88 88    88 88V8o 88
  `Y8b. 88~~~   88    88 88    88 88 V8o88
db   8D 88      `8b  d8' `8b  d8' 88  V888
`8888Y' 88       `Y88P'   `Y88P'  VP   V8P
  }

  class CLI < Thor
    default_task :hello

    desc "compile SOURCE DESTINATION", "Compile file and exit"
    def compile(source, destination = nil)
      if tree = Spoon::Parser.new.parse_with_debug(File.read(source, :encoding => "UTF-8"))
        ast = Spoon::Transformer.new.apply tree
        result = Spoon::Compiler.new(source).compile ast

        unless destination == nil
          File.write(destination, result)
        else
          puts result
        end
      end
    end

    desc "tree FILE", "Print file AST and exit"
    def tree(file)
      if tree = Spoon::Parser.new.parse_with_debug(File.read(file))
        ast = Spoon::Transformer.new.apply tree
        puts ast
      end
    end

    desc "hello", "I greet you!"
    def hello
      puts BANNER.colorize :light_cyan
      puts "Spoon #{Spoon::VERSION} - https://spoonlang.org\n".bold

      invoke :help
    end

    desc "version", "Print current version and exit"
    def version
      puts Spoon::VERSION
    end
  end
end
