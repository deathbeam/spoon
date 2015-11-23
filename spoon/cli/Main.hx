package spoon.cli;

#if cli
import mcli.Dispatch;

/**
* Entry point for Raxe CLI
**/
class Main {
  public static function main() {
    var args = Sys.args();
    // Sys.setCwd(args.pop()); // Workaround for correct working directory when running from `haxelib`
    // Execute `mcli` argument dispatcher
    new Dispatch(args).dispatch(new Cli());
  }
}
#end
