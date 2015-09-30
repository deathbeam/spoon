package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
  	var args = Sys.args();
  	args.pop();
  	trace(args);
    new Dispatch(args).dispatch(new Cli());
  }
}