package raxe;

class SemicolonTranspiler implements Transpiler {
  public function new() {}
  
  public function tokens() : Array<String> {
    return [
      "{", "}", "[", "]", "(", ")", ",", ":",
      "//", "/*", "*/", "\"", "\\\"", "=",
      "break", "continue", "return",
      "else if", "if", "else", "while", "for"
    ];
  }

  public function transpile(handle : StringHandle, packagepath : String, name : String) {
    var last = "";
    var counter : Array<Int> = new Array<Int>();

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
      } else if (handle.is("if") || handle.is("while") || handle.is("else") || handle.is("for") || handle.is("else if")) {
        counter.push(0);
        last = handle.current;
        handle.increment();
      } else if (handle.is("{")) {
        if (counter.length > 0) {
          counter[counter.length - 1] = counter[counter.length - 1] + 1;
        }
        last = handle.current;
        handle.increment();
      } else if (handle.is("}")) {
        if (counter.length > 0) {
          counter[counter.length - 1] = counter[counter.length - 1] -1;
        }
        last = handle.current;
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
            if (counter.length == 0 || counter[counter.length - 1] != 0) {
              handle.insert(";");
              handle.increment();
            }

            if (counter.length > 0 && counter[counter.length - 1] == 0) {
              counter.pop();
            }
          }

          if (handle.is("//")) {
            handle.next("\n");
            handle.increment();
          } 
        }
        
        
        last = handle.current;
        handle.increment();
      }

      trace(counter);
    }

    return handle.content;
  }
}