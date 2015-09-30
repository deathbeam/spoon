package raxe.transpiler;

import raxe.tools.StringHandle;

class CoreTranspiler implements Transpiler {
  public function new() {}

  var script : Bool = false;
  var path : String = "";
  var name : String = "";

  public function setIsScript(script : Bool) : CoreTranspiler {
    this.script = script;
    return this;
  }

  public function setPath(path : String) : CoreTranspiler {
    this.path = path;
    return this;
  }

  public function setName(name : String) : CoreTranspiler {
    this.name = name;
    return this;
  }

  public function tokens() : Array<String> {
    return [
      // Line break
      "\n",

      // Inheritance & interfaces
      "<", "::",

      // Anonymous functions
      "=>",

      // Standard keywords
      "\"", "\\\"", "(", ")", "/", "=", "#", ",", "@", ":",

      // Raxe keywords
      "-", "require", "def", "self.new", ".new", "self.", "self", "new", "end", "do",

      // Haxe keywords
      "using", "inline", "typedef", "try", "catch", //"//", "import", "var", "function",

      // Expressions
      "elsif", "if", "else", "while", "for", "then",

      // Types
      "class", "enum", "abstract", "interface",

      // Modifiers
      "private", "public", "fixed", "inline"
    ];
  }

  public function transpile(handle : StringHandle) {
    var alreadyDefined = script;
    var isFixed = false;
    var fullyFixed = false;

    if (!script) {
      handle.insert("package " + path + ";using Lambda;using StringTools;").increment();
    }

    while (handle.nextToken()) {
      // Process comments and ignore everything in
      // them until end of line or until next match if multiline
      if (handle.is("-")) {
        var comment = "";
        var position = handle.position;

        while(handle.nextTokenLine()) {
          handle.increment();

          if (handle.is("-")) {
            comment += "-";
          } else {
            break;
          }
        }

        handle.position = position;
        handle.current = "-";

        if (comment.length > 2) {
          handle.remove(comment);
          handle.insert("/* ");
          handle.increment();
          handle.next(comment);
          handle.remove(comment);
          handle.insert(" */");
          handle.increment();
        } else if (comment.length == 2) {
          handle.remove(comment);
          handle.insert("//");
          handle.increment();
          handle.next("\n");
          handle.increment();
        } else {
          handle.increment();
        }
      }
      // Skip compiler defines
      else if (handle.is("#") || handle.is("@")) {
        handle.next("\n");
      }
      // Step over things in strings (" ") and process multiline strings
      else if (handle.is("\"")) {
        if (handle.at("\"\"\"")) {
          handle.remove("\"\"\"");
          handle.insert("\"");
        }

        handle.increment();

        while (handle.nextToken()) {
          if (handle.is("#")) {
            handle.remove();
            handle.insert("$");
            handle.increment();
          } else if (handle.is("\"")) {
            break;
          } else {
            handle.increment();
          }
        }

        if (handle.at("\"\"\"")) {
          handle.remove("\"\"\"");
          handle.insert("\"");
        }

        handle.increment();
      }
      else if (handle.is("self.new")) {
        handle.remove();
        handle.insert("new " + name);
        handle.increment();
      }
      else if (handle.is(".new")) {
        handle.remove();
        handle.prevTokenLine();

        if (handle.is(")")) {
          handle.prev("(");
          handle.prevTokenLine();
        }

        handle.increment();
        handle.insert("new ");
        handle.increment();
      }
      else if (handle.safeis("try")) {
        handle.increment();
        handle.insert("{");
        handle.increment();
      }
      else if (handle.safeis("catch")) {
        handle.insert("}");
        handle.increment();
        handle.increment("catch");
        handle.insert("(");
        handle.next("\n");
        handle.insert("){");
        handle.increment();
      }
      // Change end to classic bracket end
      else if (handle.safeis("end")) {
        handle.remove();
        handle.insert("}");
        handle.increment();
      }
      // Change require to classic imports
      else if (handle.safeis("require")) {
        if (script) {
          handle.increment();
          continue;
        }

        handle.remove();
        handle.insert("import");
        handle.increment();

        var firstQuote = true;

        while (handle.nextToken()) {
          if (handle.is("\"")) {
            handle.remove();

            if (!firstQuote) {
              handle.increment();
              break;
            }

            firstQuote = false;
          } else if (handle.is("/")) {
            handle.remove();
            handle.insert(".");
          }

          handle.increment();
        }
      }
      // Defines to variables and functions
      else if (handle.safeis("def")) {
        handle.remove("def");
        var position = handle.position;
        safeNextToken(handle);

        if (handle.safeisStart("self.")) {
          handle.remove();
          handle.position = position;
          handle.insert("static ");
          handle.increment();
          position = handle.position;
          safeNextToken(handle);
        }

        var insertDynamic = true;

        if (handle.safeis("new")) {
          insertDynamic = false;
          handle.increment();
          handle.nextToken();
        }

        insertDynamic = insertDynamic && !script;

        if (fullyFixed || isFixed) {
          insertDynamic = false;
        }

        if (handle.is("(")) {
          handle.position = position;

          if (insertDynamic) {
            handle.insert("dynamic function");
          } else {
            handle.insert("function");
          }
          
          consumeCurlys(handle);
          handle.next("\n");
          handle.insert("{");
          handle.increment();
        } else {
          handle.position = position;
          handle.insert("var");
          handle.increment();
        }

        isFixed = false;
      }
      // Defines to variables and functions
      else if (handle.is("=>")) {
        var position = handle.position;
        handle.prevToken();
        handle.position = position;

        if (handle.is(")")) {
          handle.remove("=>");
          handle.prev("(");
          handle.insert("function");
          consumeCurlys(handle);
          handle.insert("{");
        }

        handle.increment();
      }
      // Insert begin bracket after if and while
      else if (handle.safeis("if")) {
        handle.increment();
        handle.insert("(");

        while (handle.nextToken()) {
          if (handle.safeis("then")) {
            handle.remove();
            break;
          }

          handle.increment();
        }

        handle.insert(")");
        handle.insert("{", true);
        handle.increment();
      }
      // Change elseif to else if and insert begin and end brackets around it
      else if (handle.safeis("elsif")) {
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        handle.insert("(");

        while (handle.nextToken()) {
          if (handle.safeis("then")) {
            handle.remove();
            break;
          }

          handle.increment();
        }

        handle.insert(")");
        handle.insert("{", true);
        handle.increment();
      }
      else if (handle.safeis("while") || handle.safeis("for")) {
        handle.increment();
        handle.insert("(");

        while (handle.nextToken()) {
          if (handle.safeis("do")) {
            handle.remove();
            break;
          }

          handle.increment();
        }

        handle.insert(")");
        handle.insert("{", true);
        handle.increment();
      }
      else if (handle.safeis("next")) {
        handle.remove();
        handle.insert("continue");
        handle.increment();
      }
      // Inser begin and end brackets around else but do not try to
      // process curlys because there will not be any
      else if (handle.safeis("else")) {
        handle.insert("}");
        handle.increment();
        handle.increment("else");
        handle.insert("{");
        handle.increment();
      }
      else if (handle.safeis("fixed")) {
        handle.remove();
        isFixed = true;
      }
      else if (handle.safeis("inline")) {
        isFixed = true;
        handle.increment();
      }
      // [abstract] class/interface/enum
      else if (handle.safeis("class") || handle.safeis("interface") || handle.safeis("enum")) {
        if (isFixed) {
          fullyFixed = true;
          isFixed = false;
        }

        handle.increment();

        while(handle.nextToken()) {
          if (handle.is("self")) {
            handle.remove();
            handle.insert(name);
          } else if (handle.is("<")) {
            handle.remove();
            handle.insert("extends");
          } else if (handle.is("::")) {
            handle.remove();
            handle.insert("implements");
          } else if (handle.is("\n")) {
            handle.insert("{");
            break;
          }

          handle.increment();
        }
      }
      else if (handle.safeisStart("self.")) {
        handle.remove();
        handle.insert(name + ".");
        handle.increment();
      }
      else {
        handle.increment(); // Skip this token
      }
    }

    if (!script) {
      handle.content = handle.content + "\n}";
    }

    return handle.content;
  }

  private function safeNextToken(handle : StringHandle) : Bool {
    handle.nextToken();

    if (safeCheck(handle, "def") && safeCheck(handle, "if") && safeCheck(handle, "elsif") && safeCheck(handle, "end")  &&
        safeCheck(handle, "self")  && safeCheck(handle, "while") && safeCheck(handle, "for") && safeCheck(handle, "next") &&
        safeCheck(handle, "do") && safeCheck(handle, "else") && safeCheck(handle, "require")) {
      return true;
    } else {
      handle.increment();
      return safeNextToken(handle);
    }
  }

  private function safeCheck(handle : StringHandle, content : String) : Bool {
    if (handle.is(content)) {
      return handle.safeis(content);
    }

    return true;
  }

  private function consumeCurlys(handle : StringHandle) {
    var count = 0;

    while(handle.nextToken()) {
      if (handle.is("(")) {
        count++;
      } else if (handle.is(")")) {
        count--;
      }

      handle.increment();
      if (count == 0) break;
    }
  }
}
