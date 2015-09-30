package raxe.transpiler;

import raxe.tools.StringHandle;

interface Transpiler {
  public function tokens() : Array<String>;
  public function transpile(handle : StringHandle) : String;
}