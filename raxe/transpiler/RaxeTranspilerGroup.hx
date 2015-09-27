package raxe.transpiler;

import raxe.tools.StringHandle;

import sys.io.File;

class RaxeTranspilerGroup extends TranspilerGroup {
  public function new() {
    super();
  }

  public function transpile(directory : String, file : String) : String {
    var currentPackage = StringTools.replace(file, directory, "");
    currentPackage = StringTools.replace(currentPackage, "\\", "/");
    var currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".rx", "");
    currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = StringTools.replace(currentPackage, "/", ".");

    if (currentPackage.charAt(0) == ".") currentPackage = currentPackage.substr(1);

    var content = File.getContent(file);

    push(new CoreTranspiler().setName(currentModule).setPath(currentPackage));
    push(new AccessTranspiler());
    push(new SemicolonTranspiler());

    for (transpiler in transpilers) {
      content = transpiler.transpile(new StringHandle(content, transpiler.tokens()));
    }

    return content;
  }
}