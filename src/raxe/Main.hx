package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
  	Sys.args().pop();
  	trace(Sys.args());
    new Dispatch(Sys.args()).dispatch(new Cli());
  }
}