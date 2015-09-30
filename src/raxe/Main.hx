package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
  	trace(Sys.args().slice(1));
    new Dispatch(Sys.args().slice(1)).dispatch(new Cli());
  }
}