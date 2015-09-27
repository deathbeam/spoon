package raxe.script;

import haxe.io.Input;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;

class RaxeScript extends Interp {
  var parser : Parser;
  var group : RaxeScriptTranspilerGroup;

  public function new() {
    super();

    parser = new Parser();
    group = new RaxeScriptTranspilerGroup();
  }

  public function parse(s : String) : Expr {
    return parser.parseString(group.transpile(s));
  }
}