package raxe.transpiler;

import raxe.tools.StringHandle;

import sys.io.File;

class RaxeScriptTranspilerGroup extends TranspilerGroup {
  public function new() {
    super();
  }

  public function transpile(content : String) : String {
    var ct = new CoreTranspiler();
    ct.script = true;

    push(ct);
    push(new AccessTranspiler());
    push(new SemicolonTranspiler());

    for (transpiler in transpilers) {
      content = transpiler.transpile(new StringHandle(content, transpiler.tokens()));
    }

    return content;
  }
}