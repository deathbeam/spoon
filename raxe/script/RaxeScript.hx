package raxe.script;

import haxe.io.Input;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import sys.io.File;

class RaxeScript extends Interp {
  var parser : Parser;
  var group : RaxeScriptTranspilerGroup;

  public function new() {
    super();

    parser = new Parser();
    group = new RaxeScriptTranspilerGroup();

    variables.set("require", function(path) {
      return execute(parse(File.getContent(path)));
    });
  }

  public function parse(s : String) : Expr {
    var content = group.transpile(s);
    trace(content);
    return parser.parseString(content);
  }
}