package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
  	var args = Sys.args();
  	trace(Sys.getCwd());
  	Sys.setCwd(args.pop());
  	trace(Sys.getCwd());
    new Dispatch(args).dispatch(new Cli());
  }
}