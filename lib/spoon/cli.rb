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

    desc "compile FILE", "Print compiled file and exit"
    def compile(file)
      tree = Spoon::Parser.new.parse_with_debug(File.read(file))
      ast = Spoon::Transformer.new.apply tree
      result = Spoon::Compiler.new(file).compile ast
      puts result.to_s
    end

    desc "tree FILE", "Print file AST and exit"
    def tree(file)
      file = Spoon::Parser.new.parse_with_debug(File.read(file))
      ast = Spoon::Transformer.new.apply file
      puts ast
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
