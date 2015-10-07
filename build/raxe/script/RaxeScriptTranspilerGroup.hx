package raxe.script;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.transpiler.CoreTranspiler;
import raxe.transpiler.AccessTranspiler;
import raxe.transpiler.SemicolonTranspiler;
import raxe.transpiler.TranspilerGroup;
import raxe.tools.StringHandle;
import sys.io.File;

class RaxeScriptTranspilerGroup extends TranspilerGroup{

public function new(){
  super();
};

public function transpile(content : String) : String return{
  push(new CoreTranspiler().setIsScript(true));
  push(new SemicolonTranspiler());

  for(transpiler in transpilers){
    content = transpiler.transpile(new StringHandle(content, transpiler.tokens()));
  }

  return content;
};

}