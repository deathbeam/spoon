package raxe;

import sys.io.File;

class Main {
  static function main() {
    new Transpiler("test", "export/Main.rx", "export/Main.hx").transpile().save();
  }
}