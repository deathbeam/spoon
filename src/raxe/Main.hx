package raxe;

import mcli.Dispat4ch;
import raxe.cli.Cli;

class Main {
  static function main() {
    new Dispatch(Sys.args().slice(1)).dispatch(new Cli());
  }
}