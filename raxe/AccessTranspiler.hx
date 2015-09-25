package raxe;

class AccessTranspiler implements Transpiler {
  public function new() {}
  
  public function tokens() : Array<String> {
    return [
      "{", "}", "[", "]", "(", ")",
      "//", "/*", "*/", "\"", "\\\"",
      "var", "function", "public", "private"
    ];
  }

  public function transpile(handle : StringHandle, packagepath : String, name : String) {
    var count = -1;
    var notPublic = false;

    while(handle.nextToken()) {
      if (handle.is("\"")) {
        handle.increment();
        handle.next("\"");
        handle.increment();
      } else if (handle.is("//")) {
        handle.increment();
        handle.next("\n");
        handle.increment();
      } else if (handle.is("/*")) {
        handle.increment();
        handle.next("*/");
        handle.increment();
      } else if (handle.is("[") || handle.is("{")) {
        count++;
        handle.increment();
      } else if (handle.is("]") || handle.is("}")) {
        count--;
        handle.increment();
      } else if (handle.is("public") || handle.is("private")) {
        notPublic = true;
        handle.increment();
      } else if (handle.is("var") || handle.is("function")) {
        var current = handle.current;

        if (count == 0 && !notPublic) {
          handle.insert("public ");
          handle.increment();
        }
        
        notPublic = false;
        handle.increment(current);
      } else {
        handle.increment();
      }
    }

    return handle.content;
  }
}