require "awesome_print"
require "colorize"
require "thor"
require "pp"

require "spoon/parser"
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
    default_task :welcome

    desc "dev", "Just dev things"
    def dev
      pp Spoon::Parser.new.parse_with_debug %{
        # Test

        def a(b, c)
          return b, c, 5
      }
    end


    desc "welcome", "Prints welcome message and help to console"
    def welcome
      puts BANNER.colorize :light_cyan
      puts "Spoon #{Spoon::VERSION} - https://spoonlang.org\n".bold

      invoke :help
    end

    desc "version", "Current version"
    def version
      puts Spoon::VERSION
    end
  end
end
