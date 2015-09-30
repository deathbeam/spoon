package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
  	var args = Sys.args();
  	Sys.setCwd(args.pop());
    new Dispatch(args).dispatch(new Cli());
  }
}