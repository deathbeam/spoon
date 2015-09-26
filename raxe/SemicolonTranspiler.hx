package raxe;

class SemicolonTranspiler implements Transpiler {
  public function new() {}
  
  public function tokens() : Array<String> {
    return [
      "@", "{", "}", "[", "]", "(", ")", ",", ":", 
      "//", "/*", "*/", "\"", "\\\"", "=",
      "break", "continue", "return",
      "if", "while", "for"
    ];
  }

  public function transpile(handle : StringHandle, packagepath : String, name : String) {
    var last = "";
    var counter : Array<Int> = new Array<Int>();

    while(handle.nextTokenLine()) {
      if (handle.is("@")) {
        handle.increment();
        handle.next("\n");
        handle.increment();
      } else if (handle.is("\"")) {
        handle.increment();
        handle.next("\"");
        handle.increment();
      } else if (handle.is("/*")) {
        handle.increment();
        handle.next("*/");
        handle.increment();
      } else if (handle.safeis("if") || handle.safeis("while") || handle.safeis("for")) {
        counter.push(0);
        last = handle.current;
        handle.increment();
      } else if (handle.is("{")) {
        if (counter.length > 0) {
          counter[counter.length - 1] = counter[counter.length - 1] + 1;
        }

        last = handle.current;
        handle.increment();
      } else {
        if (handle.is("\n") || handle.is("//") || handle.is("}")) {
          var position = handle.position;

          if (last == "}" || last == "]") {
            handle.nextToken();
            handle.position = position;

            if (handle.is(")") || handle.is("@")) {
              handle.increment();
              continue;
            }
          }

          if (last == "}" || last == "]" || last == ")" || last == "\"" || last == "=" || last == ":" || last == ")" || last == "continue" || last == "break" || last == "return") {
            if (counter.length == 0 || counter[counter.length - 1] != 0) {
              handle.insert(";");
              handle.increment();
            } else {
              counter.pop();
            }
          }

          if (handle.is("//")) {
            handle.next("\n");
            handle.increment();
          }

          if (handle.is("}")) {
            if (counter.length > 0) {
              counter[counter.length - 1] = counter[counter.length - 1] -1;
            }
          }
        }
        
        last = handle.current;
        handle.increment();
      }
    }

    return handle.content;
  }
}