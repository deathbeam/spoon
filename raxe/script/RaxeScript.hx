package raxe.script;

import haxe.io.Input;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import sys.io.File;
import sys.FileSystem;
using StringTools;

class RaxeScript extends Interp {
  var parser : Parser;
  var group : RaxeScriptTranspilerGroup;

  public function new() {
    super();

    parser = new Parser();
    group = new RaxeScriptTranspilerGroup();

    variables.set("require", function(thing : String) {
      var path = thing + ".rx";

      if (FileSystem.exists(path)) {
        return execute(parse(File.getContent(path)));
      }

      var clazz = Type.resolveClass(thing.replace("\\", ".").replace("/", "."));

      if (clazz == null) {
        trace('Failed to resolve class $thing');
        return null;
      }

      return clazz;
    });
  }

  public function parse(s : String) : Expr {
    var content = group.transpile(s);
    trace(content);
    return parser.parseString(content);
  }

  override function get(o : Dynamic, f : String ) : Dynamic {
    if (o == null) {
      #if debug
      trace('Null error when doing get "$f"');
      #end
      error(EInvalidAccess(f));
    }

    return Reflect.getProperty(o,f);
  }

  override function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
    if (o == null) {
      #if debug
      trace('Null error when doing set "$f"');
      #end
      error(EInvalidAccess(f));
    }

    Reflect.setProperty(o,f,v);
    return v;
  }
}
