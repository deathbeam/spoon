package raxe;

import sys.io.File;

class Main {
  static function main() {
    var group = new TranspilerGroup();

    group
    	.push(new CoreTranspiler()).push(new AccessTranspiler()).push(new SemicolonTranspiler());

    var content = group.transpile("test", "examples/StaticTyping.rx");
    File.saveContent("export/StaticTyping.hx", content);
    trace("\n" + File.getContent("export/StaticTyping.hx"));
  }
}