package raxe;

import sys.io.File;

class TranspilerGroup {
  var transpilers : Array<Transpiler>;

  public function new() {
    transpilers = new Array<Transpiler>();
  }

  public function push(transpiler : Transpiler) : TranspilerGroup {
    transpilers.push(transpiler);
    return this;
  }

  public function transpile(directory : String, inputFile : String) : String {
    var currentPackage = StringTools.replace(inputFile, directory, "");
      currentPackage = StringTools.replace(currentPackage, "\\", "/");
      var currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".rx", "");
      currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
      currentPackage = StringTools.replace(currentPackage, "/", ".");

      var content = File.getContent(inputFile);

      for (transpiler in transpilers) {
        content = transpiler.transpile(
          new StringHandle(content, transpiler.tokens()),
          currentPackage, currentModule);
      }

      return content;
  }
}