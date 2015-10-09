package raxe.script;using Lambda;using StringTools;// vim: set ft=rb:

import haxe.io.Input;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import sys.io.File;
import sys.FileSystem;
import raxe.transpiler.Transpiler;
import raxe.tools.StringHandle;

class RaxeScript extends Interp{

public var parser : Parser;
public var transpiler : Transpiler;

public function new(){
  super();

  parser =new  Parser();
  transpiler =new  Transpiler();

  variables.set("require", function(thing : String) return{
    var path = thing + ".rx";

    if(FileSystem.exists(path)){
      return execute(parse(File.getContent(path)));
    }

    path = thing.replace("/", ".");

    var clazz : Dynamic = Type.resolveClass(path);

    if(clazz == null){
      clazz = Type.resolveEnum(path);

      if(clazz == null){
        trace("Failed to resolve type ${thing}");
      }
    }

    return clazz;
  });
}

public function parse(s : String) : Expr return{
  var handle =new  StringHandle(s, transpiler.tokens);
  var content = transpiler.run(true, handle);
  return parser.parseString(content);
}

override public function get(o : Dynamic, f : String ) : Dynamic return{
  if(o == null){
    #if debug
    trace("Null error when doing get ${f}");
    #end
    error(EInvalidAccess(f));
  }

  return Reflect.getProperty(o,f);
}

override public function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic return{
  if(o == null){
    #if debug
    trace("Null error when doing set ${f}");
    #end
    error(EInvalidAccess(f));
  }

  Reflect.setProperty(o,f,v);
  return v;
}

}