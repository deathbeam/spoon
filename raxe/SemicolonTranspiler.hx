package raxe;

class SemicolonTranspiler implements Transpiler {
  public function new() {}
  
  public function tokens() : Array<String> {
    return [
      "{", "}", "[", "]", "(", ")", ",", ":",
      "//", "/*", "*/", "\"", "\\\"", "=",
      "break", "continue", "return"
    ];
  }

  public function transpile(handle : StringHandle, packagepath : String, name : String) {
    var last = "";

    while(handle.nextTokenLine()) {
      if (handle.is("\"")) {
        handle.increment();
        handle.next("\"");
        last = handle.current;
        handle.increment();
      } else if (handle.is("/*")) {
        handle.increment();
        handle.next("*/");
        handle.increment();
      } else {
        if (handle.is("\n") || handle.is("//")) {
          if (last == "}" || last == "]") {
            var position = handle.position;
            handle.nextToken();
            handle.position = position;

            if (handle.is(")")) {
              handle.increment();
              continue;
            }
          }

          if (last == "}" || last == "]" || last == ")" || last == "\"" || last == "=" || last == ":" || last == ")" || last == "continue" || last == "break" || last == "return") {
            handle.insert(";");
            handle.increment();
          }

          if (handle.is("//")) {
            handle.next("\n");
            handle.increment();
          } 
        }
        
        last = handle.current;
        handle.increment();
      }
    }

    return handle.content;
  }
}