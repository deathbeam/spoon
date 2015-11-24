package spoon.cli;

#if cli
import mcli.CommandLine;
import sys.FileSystem;
import sys.io.File;
import hxparse.Position;
import spoon.log.Logger;
import spoon.log.LogParser;
import spoon.parser.Parser;

class Cli extends CommandLine {

  /**
  * Source directory or file
  * @alias s
   **/
  public var src : String;

  /**
  * Destination directory or file
  * @alias d
   **/
  public var dest : String;

  /**
  * Execute the command when source file(s) are changed
  * @alias w
   **/
  public var watch : Bool;

  /**
  * Copy all (not only .spoon) files to dest directory
  * @alias a
   **/
  public var all : Bool;

  /**
  * Specify dump output type (default "simple", "yaml", "cson", "json", "xml")
   **/
  public var dump : String;

  /**
  * Show this message
  * @alias h
   **/
  public function help() {
    var useAscii = Sys.systemName().toLowerCase().indexOf("windows") == -1;

    if (useAscii) Sys.print("\033[1;35m\033[1m");
    Sys.print("
 .d8888. d8888b.  .d88b.   .d88b.  d8b   db
 88'  YP 88  `8D .8P  Y8. .8P  Y8. 888o  88
 `8bo.   88oodD' 88    88 88    88 88V8o 88
   `Y8b. 88~~~   88    88 88    88 88 V8o88
 db   8D 88      `8b  d8' `8b  d8' 88  V888
 `8888Y' 88       `Y88P'   `Y88P'  VP   V8P

");
    if (useAscii) Sys.print("\033[0;37m\033[1m");
    Sys.println("Spoon 0.0.1 - https://github.com/nondev/spoon");
    Sys.println("\033[0;37m\n" + this.showUsage());
    Sys.exit(0);
  }

  /**
  * Default task what is executed when none of above options is matched
   **/
  public function runDefault() {
    try {
      if (src != null) {
        compile();
      } else {
        help();
      }
    } catch(err : String) {
      Sys.println(err);
    }

    Sys.exit(0);
  }

  private function compile() {
    if(!FileSystem.exists(src)){
      throw 'Source not found';
    }

    // var compiler = new CompilerCommand(src, dest, all, verbose);

    while(true) {
      var filename = src.substr(src.lastIndexOf("/") + 1);
      var logParser = LogParserUtil.fromString(dump);
      var parser = new Parser(logParser, File.getContent(src), filename);
      var result = parser.run();

      if (result.length == 0) {
        if (Logger.self.getMessageCount() == 0) {
          Logger.self.log({
            type: Empty,
            severity: Warning,
            position: new Position(filename, 0, 0)
          });
        }
      } else {
        Sys.println(result);
      }

      if (!watch) {
        break;
      }
    }

    Logger.self.dump();
  }
}
#end
