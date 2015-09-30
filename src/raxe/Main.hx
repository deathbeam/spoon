package raxe;

import mcli.Dispatch;
import raxe.cli.Cli;

class Main {
  static function main() {
    new Dispatch(Sys.args().slice(1)).dispatch(new Cli());
  }
}