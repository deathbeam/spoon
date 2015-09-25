package raxe;

import sys.io.File;

class Main {
  static function main() {
    var group = new TranspilerGroup();

    group
    	.push(new CoreTranspiler())
    	.push(new AccessTranspiler())
    	.push(new SemicolonTranspiler());

    trace(group.transpile("test", "export/Main.rx"));
  }
}