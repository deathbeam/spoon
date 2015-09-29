package raxe.transpiler;

import raxe.tools.StringHandle;

class SemicolonTranspiler implements Transpiler {
  var counter : Array<Int> = new Array<Int>();

  public function new() {}
  
  public function tokens() : Array<String> {
    return [
      ")", "}",
      "@", "//", "/*", "/*", "\\\"", "\"",
      "=", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[",
      "if", "for", "while", "else"
    ];
  }

  public function transpile(handle : StringHandle) {
    while(handle.nextTokenLine()) {
      skipLines(handle);

      if (handle.is("\n") || handle.is("//")) {
        var position = handle.position;
        var isComment = handle.is("//");

        handle.nextToken();
        handle.position = position;

        if (!handle.isOne([")", "]"])) {
          handle.insert(";");
          handle.increment();
        }

        if (isComment) {
          handle.next("\n");
        }

        handle.increment("\n");
      } else {
        handle.increment();
      }
    }

    return handle.content;
  }

  private function skipLines(handle : StringHandle) {
    while(handle.nextTokenLine()) {
      if (handle.is("\n") || handle.is("//")) {
        var isComment = handle.is("//");
        var position = handle.position;
        handle.prevTokenLine();
        trace(handle.current);

        if (handle.isOne(["=", "+", "-", "*", ".", "/", ",", "|", "&", "{", "(", "[", "\n"]) && onlyWhitespace(handle.content, handle.position + 1, position)) {
          trace(true);
          handle.position = position;

          if (isComment) {
            handle.next("\n");
            handle.increment();
          } else {
            handle.increment("\n");
          }
        } else {
          handle.position = position;
          break;
        }
      } else if (handle.is("/*")) {
        handle.next("*/");
        handle.increment();
      } else if (handle.is("@")) {
        handle.next("\n");
        handle.increment();
      } else if (handle.safeis("if") || handle.safeis("while") || handle.safeis("for") || handle.safeis("else")) {
        if (handle.safeis("else")) {
          var position = handle.position;
          handle.nextToken();

          if (!handle.safeis("if")) {
            handle.position = position;
          }
        }

        counter.push(0);
        handle.increment();
      } else if (handle.is("{")) {
        if (counter.length > 0) {
          counter[counter.length - 1] = counter[counter.length - 1] + 1;
        }

        handle.increment();
      } else if (handle.is("}")) {
        if (counter.length > 0) {
          counter[counter.length - 1] = counter[counter.length - 1] - 1;

          if (counter[counter.length - 1] == 0) {
            counter.pop();
            handle.increment();
            handle.nextTokenLine();
          }
        }

        if (!handle.safeis("else")) {
          handle.increment();
        }
      } else {
        break;
      }
    }

    handle.nextTokenLine();
  }

  private function onlyWhitespace(content : String, from : Int, to : Int) {
    var sub = content.substr(from, to - from);
    var regex = ~/^\s*$/;
    return regex.match(sub);
  }
}