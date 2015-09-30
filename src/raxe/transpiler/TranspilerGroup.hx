package raxe.transpiler;

import raxe.tools.StringHandle;

class TranspilerGroup {
  var transpilers : Array<Transpiler>;

  public function new() {
    transpilers = new Array<Transpiler>();
  }

  public function push(transpiler : Transpiler) : TranspilerGroup {
    transpilers.push(transpiler);
    return this;
  }
}