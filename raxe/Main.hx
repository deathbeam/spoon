package raxe;

import sys.io.File;

class Main {
  static function main() {
    var group = new TranspilerGroup();

    group
      .push(new CoreTranspiler()).push(new AccessTranspiler()).push(new SemicolonTranspiler());

    var content = group.transpile("test", "examples/ModulesAndInstances.rx");
    File.saveContent("export/Test.hx", content);
    trace("\n" + File.getContent("export/Test.hx"));
  }
}