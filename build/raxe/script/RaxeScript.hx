package raxe.script;using Lambda;using StringTools;// vim: set ft=rb:

import haxe.io.Input;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import sys.io.File;
import sys.FileSystem;

class RaxeScript extends Interp{

public var parser : Parser;
public var group : RaxeScriptTranspilerGroup;

public function new(){
  super();

  parser =new  Parser();
  group =new  RaxeScriptTranspilerGroup();

  variables.set("require", function(thing : String){
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
};

public function parse(s : String) : Expr{
  var content = group.transpile(s);
  return parser.parseString(content);
};

override public function get(o : Dynamic, f : String ) : Dynamic{
  if(o == null){
    #if debug
    trace("Null error when doing get ${f}");
    #end
    error(EInvalidAccess(f));
  }

  return Reflect.getProperty(o,f);
};

override public function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic{
  if(o == null){
    #if debug
    trace("Null error when doing set ${f}");
    #end
    error(EInvalidAccess(f));
  }

  Reflect.setProperty(o,f,v);
  return v;
};

}