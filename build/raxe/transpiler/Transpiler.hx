package raxe.transpiler;using Lambda;using StringTools;import raxe.tools.StringHandle;
import sys.io.File;

class Transpiler{
  public function new(){
  }

  private var path : String = "";
  private var name : String = "";
  private var currentType : String = "";
  private var hasVisibility : Bool = false;
  private var opened : Int = -1;

  public var tokens = [
    // Line break
    "\n", ";",

    // Whitespace skip
    "#", "@", "\"",

    // Types
    "::", "class", "enum", "abstract", "interface", "module",

    // Modifiers
    "public", "private",

    // Special keywords
    "import", "def", "self", ".new", "new", "end", "do", "typedef", "try", "catch",

    // Brackets
    "{", "}", "(", ")", "[", "]",

    // Operators (- is also used for comments, < is also used for inheritance)
    ":", "?", "=", "+", "-", "*", ".", "/", "," , "|", "&",  "^", "%", "<", ">", "~",

    // Expressions
    "elsif", "if", "else", "while", "for", "case", "when",
  ];

  public function transpile(directory : String, file : String) : String return{
    var currentPackage = file.replace(directory, "");
    currentPackage = currentPackage.replace("\\", "/");
    var currentModule = currentPackage.substr(currentPackage.lastIndexOf("/") + 1).replace(".rx", "");
    currentPackage = currentPackage.replace(currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = currentPackage.replace("/", ".");

    if(currentPackage.charAt(0) == "."){
      currentPackage = currentPackage.substr(1);
    }

    var content = File.getContent(file);
    var handle =new  StringHandle(content, tokens);

    name = currentModule;
    path = currentPackage;

    return run(false, handle);
  }

  public function run(script : Bool, handle : StringHandle) return{
    if(!script){
      handle.insert("package " + path + ";using Lambda;using StringTools;").increment();
    }

    while (handle.nextToken()){
      if(script){
        opened = -1;
      }

      // Skip compiler defines
      if (handle.is("#") || handle.is("@")){
        handle.next("\n");
        handle.increment();
      // Step over things in strings (" ") and process multiline strings
      }else if(handle.is("\"")){
        consumeStrings(handle);
      // Correct access
      }else if(handle.safeis("public") || handle.safeis("private")){
        hasVisibility = true;
        handle.increment();
      }else if(handle.is("{")){
        opened = opened + 1;
        handle.increment();
      }else if(handle.is("}")){
        opened = opened - 1;

        if(opened == -1){
          currentType = "";
        }

        handle.increment();
      }else if(handle.is(".new")){
        handle.remove();
        handle.prevTokenLine();

        while(true){
          if (!handle.isOne(["=", ":", "\n", ".", "(", "[", ";", ","])){
            if(handle.is(">")){
              handle.prev("<");
              handle.increment();
            }

            handle.prevTokenLine();
          }else{
            break;
          }
        }

        handle.increment();
        handle.insert("new ");
        handle.increment();
      }else if(handle.safeis("case")){
        handle.remove();
        handle.insert("switch");
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      }else if(handle.safeis("when")){
        handle.remove();
        handle.insert("case");
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert(":");
        handle.increment();
      }else if(handle.safeis("try")){
        handle.increment();
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      }else if(handle.safeis("catch")){
        handle.insert("}");
        handle.increment();
        handle.increment("catch");
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert("{");
        handle.increment();
      // Change end to classic bracket end
      }else if(handle.safeis("end")){
        handle.remove();
        handle.insert("}");
        handle.increment();
        opened = opened - 1;
      // Change require to classic imports
      }else if(handle.safeis("import")){
        handle.next("\n");
        handle.insert(";");
        handle.increment();
      // Defines to variables and functions
      }else if(handle.safeis("def")){
        handle.remove("def");

        if(opened == 0){
          if(!hasVisibility){
            handle.insert("public ");
            handle.increment();
          }

          if(currentType == "module"){
            handle.insert("static ");
            handle.increment();
          }
        }

        hasVisibility = false;

        var position = handle.position;
        safeNextToken(handle);

        if(handle.safeis("self")){
          handle.remove("self.");
          handle.position = position;
          handle.insert("static ");
          handle.increment();
          position = handle.position;
          safeNextToken(handle);
        }

        var implicit = true;

        if(handle.safeis("new")){
          implicit = false;
          handle.increment();
          handle.nextToken();
        }

        if(handle.is("(")){
          handle.position = position;
          handle.insert("function");
          consumeBrackets(handle, "(", ")");
          handle.next("\n");

          if(currentType != "interface"){
            if (implicit){
              handle.insert(" return{");
            }else{
              handle.insert("{");
            }

            opened = opened + 1;
          }else{
            handle.insert(";");
          }

          handle.increment();
        }else{
          handle.position = position;
          handle.insert("var");
          handle.increment();
        }
      // Closures and blocks
      }else if(handle.safeis("do")){
        var position = handle.position;
        handle.increment();
        handle.nextToken();
        handle.position = position;

        if(handle.is("(")){
          handle.remove("do");
          handle.insert("function");
          handle.increment();
          consumeBrackets(handle, "(", ")");
          handle.insert(" return{");
        }else{
          handle.remove("do");
          handle.insert("{");
        }

        opened = opened + 1;

        handle.increment();
      // Insert begin bracket after if and while
      }else if(handle.safeis("if")){
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      // Change elseif to else if and insert begin and end brackets around it
      }else if(handle.safeis("elsif")){
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert("{");
        handle.increment();
      }else if(handle.safeis("while") || handle.safeis("for")){
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, "(", ")");
        handle.insert("{");
        opened = opened + 1;
        handle.increment();
      // Inser begin and end brackets around else but do not try to
      // process curlys because there will not be any
      }else if(handle.safeis("else")){
        handle.insert("}");
        handle.increment();
        handle.increment("else");
        handle.insert("{");
        handle.increment();
      // [abstract] class/interface/enum
      }else if (handle.safeis("class") || handle.safeis("interface") || handle.safeis("enum") || handle.safeis("module")){
        currentType = handle.current;

        if(currentType == "module"){
          handle.remove();
          handle.insert("class");
        }

        handle.increment();

        while(handle.nextToken()){
          if(handle.is("self")){
            handle.remove();
            handle.insert(name);
          }else if(handle.is("<")){
            handle.remove();
            handle.insert("extends");
          }else if(handle.is("::")){
            handle.remove();
            handle.insert("implements");
          }else if(handle.is("\n")){
            handle.insert("{");
            break;
          }

          handle.increment();
        }
      }else if(handle.safeis("self")){
        handle.remove();
        handle.insert(name);
        handle.increment();
        // Process comments and ignore everything in
        // them until end of line or until next match if multiline
      }else if(handle.is("\n") || handle.is("-")){
        var pos = handle.position;
        var insert = true;
        var isComment = handle.is("-");

        if (isComment && !handle.at("--")){
          handle.increment();
          continue;
        }

        handle.prevTokenLine();

        if (handle.isOne(["=", ";", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "~", "\n", "}", "?", ":"]) && onlyWhitespace(handle.content, handle.position + 1, pos)){
            insert = false;
        }

        handle.position = pos;

        if(!isComment){
          handle.increment("\n");
          handle.nextToken();

          if (handle.isOne(["?", ":", "=", "+", "-", "*", ".", "/", "," , "|", "&", ")", "]", "^", "%", "~"]) && onlyWhitespace(handle.content, pos + 1, handle.position - 1)){
              if(handle.is("-") && !handle.at("--")){
                insert = false;
              }
          }

          handle.prev("\n");
        }

        if (insert){
          handle.insert(";");
          handle.increment();
        }

        if(isComment){
          var comment = "";
          var position = handle.position;

          while(handle.nextTokenLine()){
            if(handle.is("-")){
              if (comment != "" && handle.content.charAt(handle.position - 1) != "-"){
                handle.increment();
                break;
              }else{
                comment += "-";
                handle.increment();
              }
            }else{
              handle.increment();
              break;
            }
          }

          handle.position = position;
          handle.current = "-";

          if(comment.length > 2){
            handle.remove(comment);
            handle.insert("/** ");
            handle.increment();
            handle.next(comment);
            handle.remove(comment);
            handle.insert(" **/");
            handle.increment();
          }else if(comment.length == 2){
            handle.remove(comment);
            handle.insert("//");
            handle.increment();
            handle.next("\n");
            handle.increment();
          }else{
            handle.increment();
          }
        }else{
          handle.increment();
        }
      // Skip this token
      }else{
        handle.increment();
      }
    }

    return handle.content;
  }

  private function safeNextToken(handle : StringHandle) : Bool return{
    handle.nextToken();

    if (safeCheck(handle, "def") && safeCheck(handle, "if") && safeCheck(handle, "elsif") && safeCheck(handle, "end")  &&
        safeCheck(handle, "self")  && safeCheck(handle, "while") && safeCheck(handle, "for") && safeCheck(handle, "import") &&
        safeCheck(handle, "do") && safeCheck(handle, "else") && safeCheck(handle, "try") && safeCheck(handle, "catch") &&
        safeCheck(handle, "private") && safeCheck(handle, "public")){
      return true;
    }else{
      handle.increment();
      return safeNextToken(handle);
    }
  }

  private function safeCheck(handle : StringHandle, content : String) : Bool return{
    if(handle.is(content)){
      return handle.safeis(content);
    }

    return true;
  }

  private function consumeBrackets(handle : StringHandle, startSymbol : String, endSymbol : String) return{
    var count = 0;

    while(handle.nextToken()){
      if(handle.is("\"")){
        consumeStrings(handle);
      }else if(handle.is(startSymbol)){
        count = count + 1;
        handle.increment();
      }else if(handle.is(endSymbol)){
        count = count - 1;
        handle.increment();
      }else{
        handle.increment();
      }

      if (count == 0){
        break;
      }
    }
  }

  private function consumeStrings(handle : StringHandle) return{
    if(handle.at("\"\"\"")){
      handle.remove("\"\"\"");
      handle.insert("\"");
    }

    handle.increment();

    while(handle.nextToken()){
      if(handle.is("#")){
        if(handle.content.charAt(handle.position + 1) == "{"){
          handle.remove();
          handle.insert("$");
        }

        handle.increment();
      }else{
        if(handle.is("\"") &&
            (handle.content.charAt(handle.position -1) != "\\" ||
            (handle.content.charAt(handle.position -1) == "\\" &&
            handle.content.charAt(handle.position -2) == "\\"))){
          break;
        }

        handle.increment();
      }
    }

    if(handle.at("\"\"\"")){
      handle.remove("\"\"\"");
      handle.insert("\"");
    }

    handle.increment();
  }

  public function onlyWhitespace(content : String, from : Int, to : Int) return{
    var sub = content.substr(from, to - from);
    var regex =new  EReg("^\\s*$", "");
    return regex.match(sub);
  }
}
