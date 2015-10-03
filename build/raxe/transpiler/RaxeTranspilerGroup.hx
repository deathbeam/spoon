package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;
import sys.io.File;

class RaxeTranspilerGroup extends TranspilerGroup{

public function new(){
  super();
};

dynamic public function transpile(directory : String, file : String) : String{
  var currentPackage = file.replace(directory, "");
  currentPackage = currentPackage.replace("\\", "/");
  var currentModule = currentPackage.substr(currentPackage.lastIndexOf("/") + 1).replace(".rx", "");
  currentPackage = currentPackage.replace(currentPackage.substr(currentPackage.lastIndexOf("/")), "");
  currentPackage = currentPackage.replace("/", ".");

  if(currentPackage.charAt(0) == "."){
    currentPackage = currentPackage.substr(1);
  }

  var content = File.getContent(file);

  push(new CoreTranspiler().setName(currentModule).setPath(currentPackage));
  push(new AccessTranspiler());
  push(new SemicolonTranspiler());

  for(transpiler in transpilers){
    content = transpiler.transpile(new StringHandle(content, transpiler.tokens()));
  }

  return content;
};

}