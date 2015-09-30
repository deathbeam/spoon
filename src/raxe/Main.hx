package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;
using StringTools;

class Main {
  static function main() {
    var args : Array<String> = Sys.args();
    
    if (args[1] == Sys.executablePath()) {
      args = args.slice(1);
    }

    new Dispatch(args).dispatch(new Cli());
  }
}