package raxe.compiler;using Lambda;using StringTools;import raxe.tools.StringHandle;
import sys.io.File;

/** 
* The most important Raxe class, which compiles Raxe source to Haxe source
 **/
class Compiler{
  public function new()  null;

  private var name : String = "";
  private var currentType : String = "";
  private var currentExpression : String = "";
  private var hasVisibility : Bool = false;
  private var opened : Int = -1;
  private var currentOpened : Int = -1;

  /** 
  * Array of tokens used for StringHandle to correctly parse Raxe files
   **/
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
    "import", "def", "self", "new", "end", "do", "typedef", "try", "catch", "empty",

    // Brackets
    "{", "}", "(", ")", "[", "]", "=>",

    // Operators (- is also used for comments, < is also used for inheritance)
    ":", "?", "=", "+", "-", "*", ".", "/", "," , "|", "&",  "^", "%", "<", ">", "~",

    // Expressions
    "elsif", "if", "else", "while", "for", "switch", "when",
  ];

  /** 
  * Compile Raxe file and returns Haxe result
  * @param directory root project directory, needed for correct package names
  * @param file file path to compile
  * @return Raxe file compiled to it's Haxe equivalent
   **/
  public function compile(directory : String, file : String) : String return{
    var currentPackage = file
      .replace(directory, "")
      .replace("\\", "/");

    name = currentPackage
      .substr(currentPackage.lastIndexOf("/") + 1)
      .replace(".rx", "");

    currentPackage = currentPackage
      .replace(currentPackage.substr(currentPackage.lastIndexOf("/")), "")
      .replace("/", ".");

    if(currentPackage.charAt(0) == "."){
      currentPackage = currentPackage.substr(1);
    }

    var content = File.getContent(file);
    var handle = new StringHandle(content, tokens);
    handle.insert("package " + currentPackage + ";using Lambda;using StringTools;").increment();

    return run(handle).content;
  }

  /** 
  * Process content of StringHandle and return it modified
  * @param script Determine if automatically insert package and class names
  * @param handle Handle with initial content and position
  * @return modified string handle with adjusted position and content
   **/
  public function run(handle : StringHandle, script : Bool = false, endPosition : Int = -1) : StringHandle return{
    while(handle.nextToken()){
      // Skip compiler defines and annotations
      if (handle.is("@")){
        handle.next("\n");
        handle.increment();
      // Step over things in strings (" ") and process multiline strings
      }else if(handle.is("\"")){
        consumeStrings(handle);
      // Correct access
      }else if(handle.safeis("public") || handle.safeis("private")){
        hasVisibility = true;
        handle.increment();
      // Change require to classic imports
      }else if(handle.safeis("import")){
        handle.next("\n");
        handle.insert(";");
        handle.increment();
      // Empty operator (null)
      }else if(handle.safeis("empty")){
        handle.remove();
        handle.insert("null");
        handle.increment();
      // Replace self with current module name
      }else if(handle.safeis("self")){
        handle.remove();
        handle.insert(name);
        handle.increment();
      // Structures and arrays
      }else if(handle.is("{") || handle.is("[")){
        opened = opened + 1;
        handle.increment();
      }else if(handle.is("}") || handle.is("]")){
        opened = opened - 1;

        if(opened == -1){
          currentType = "";
        }

        handle.increment();
      // Change end to classic bracket end
      }else if(handle.safeis("end")){
        handle.remove();
        handle.insert("}");
        handle.increment();
        opened = opened - 1;

        if(currentOpened == opened){
          currentOpened = -1;
          currentExpression = "";
        }
      // Insert begin bracket after switch
      }else if(handle.safeis("switch")){
        currentExpression = handle.current;
        currentOpened = opened;
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      // Replaced when with Haxe "case"
      }else if(handle.safeis("when")){
        handle.remove();
        handle.insert("case");
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert(":");
        handle.increment();
      // Insert begin bracket after try
      }else if(handle.safeis("try")){
        handle.increment();
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      // Insert brackets around catch
      }else if(handle.safeis("catch")){
        handle.insert("}");
        handle.increment();
        handle.increment("catch");
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert("{");
        handle.increment();
      // Insert begin bracket after if and while
      }else if(handle.safeis("if")){
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert("{");
        handle.increment();
        opened = opened + 1;
      // Change elseif to else if and insert begin and end brackets around it
      }else if(handle.safeis("elsif")){
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert("{");
        handle.increment();
      // Insert begin brackets after loops declaration
      }else if(handle.safeis("while") || handle.safeis("for")){
        handle.increment();
        handle.nextToken();
        consumeBrackets(handle, script, "(", ")");
        handle.next("\n");
        handle.insert("{");
        opened = opened + 1;
        handle.increment();
      // Inser begin and end brackets around else but do not try to
      // process curlys because there will not be any
      }else if(handle.safeis("else")){
        if(currentExpression == "switch"){
          handle.remove();
          handle.insert("default:");
        }else{
          handle.insert("}");
          handle.increment();
          handle.increment("else");
          handle.insert("{");
        }

        handle.increment();
      // Defines to variables and functions
      }else if(handle.safeis("def")){
        handle.remove("def");

        if(opened == 0 && !script){
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
          consumeBrackets(handle, script, "(", ")");

          if(currentType != "interface"){
            while(safeNextToken(handle)){
              if(handle.is("=>")){
                handle.remove();

                if(implicit){
                  handle.insert("return");
                }

                break;
              }else if(handle.isOne(["\n", "#"])){
                if(implicit){
                  handle.insert(" return{");
                }else{
                  handle.insert("{");
                }
                handle.increment();
                opened = opened + 1;
                break;
              }else{
                handle.increment();
              }
            }
          }else{
            handle.insert(";");
            handle.increment();
          }
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
          consumeBrackets(handle, script, "(", ")");

          while(safeNextToken(handle)){
            if(handle.is("=>")){
              handle.remove();
              handle.insert("return");
              break;
            }else if(handle.isOne(["\n", "#"])){
              handle.insert(" return{");
              opened = opened + 1;
              break;
            }else{
              handle.increment();
            }
          }
        }else{
          handle.remove("do");
          handle.insert("{");
          opened = opened + 1;
        }

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
      // Process comments and newlines. Also, insert semicolons when needed
      }else if(handle.is("\n") || handle.is("#")){
        var pos = handle.position;
        var insert = true;
        var isComment = handle.is("#");

        handle.prevTokenLine();

        if(handle.isOne(["=", ";", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "~", "\n", "}", "?", ":"]) && onlyWhitespace(handle.content, handle.position + 1, pos)){
          if(handle.is("-") || handle.is("+")){
            if(handle.content.charAt(handle.position - 1) != handle.current){
              insert = false;
            }
          }else{
            insert = false;
          }
        }

        handle.position = pos;

        if(!isComment){
          handle.increment("\n");
          handle.nextToken();

          if(handle.isOne(["?", ":", "=", "+", "-", "*", ".", "/", "," , "|", "&", ")", "]", "^", "%", "~"]) && onlyWhitespace(handle.content, pos + 1, handle.position - 1)){
            insert = false;
          }

          handle.prev("\n");
        }

        if(insert && !handle.atStart()){
          handle.insert(";");
          handle.increment();
        }

        if(isComment){
          consumeComments(handle);
        }else{
          handle.increment();
        }
      // Skip this token
      }else{
        handle.increment();
      }

      if(endPosition > -1 && handle.position >= endPosition){
        break;
      }
    }

    return handle;
  }

  private function safeNextToken(handle : StringHandle) : Bool return{
    handle.nextToken();

    if (safeCheck(handle, "def") && safeCheck(handle, "if") && safeCheck(handle, "elsif") && safeCheck(handle, "end")  &&
        safeCheck(handle, "self")  && safeCheck(handle, "while") && safeCheck(handle, "for") && safeCheck(handle, "import") &&
        safeCheck(handle, "do") && safeCheck(handle, "else") && safeCheck(handle, "try") && safeCheck(handle, "catch") &&
        safeCheck(handle, "private") && safeCheck(handle, "public") && safeCheck(handle, "empty") && safeCheck(handle, "switch") &&
        safeCheck(handle, "when")){
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

  private function consumeBrackets(handle : StringHandle, script : Bool, startSymbol : String, endSymbol : String) return{
    var count = 0;
    var startPosition = handle.position;

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

      if(count == 0){
        var endPosition = handle.position - endSymbol.length;

        if(startPosition < endPosition){
          handle.position = startPosition;
          handle = run(handle, script, endPosition);
          handle.position = endPosition;
        }

        break;
      }
    }
  }

  private function consumeComments(handle : StringHandle) return{
    var comment = "";
    var position = handle.position;

    while(handle.nextTokenLine()){
      if(handle.is("#")){
        comment += "#";
        handle.increment();
      }else{
        handle.increment();
        break;
      }
    }

    handle.position = position;
    handle.current = "#";

    if(comment.length > 1){
      handle.remove(comment);
      handle.insert("/** ");
      handle.increment();

      while(handle.nextToken()){
        if(handle.at(comment)){
          handle.remove(comment);
          handle.insert(" **/");
          handle.increment();
          break;
        }else if(handle.is("#")){
          position = handle.position;
          handle.prevToken();

          if(handle.is("\n") && onlyWhitespace(handle.content, position + 1, handle.position - 1)){
            handle.position = position;
            handle.remove("#");
            handle.insert("*");
          }else{
            handle.position = position;
          }

          handle.increment();
        }else{
          handle.increment();
        }
      }
    }else{
      if(handle.at("#elsif")){
        handle.remove("#elsif");
        handle.insert("#elseif");
      }else if(!handle.at("#if") && !handle.at("#else") && !handle.at("#end")){
        handle.remove(comment);
        handle.insert("//");
      }

      handle.next("\n");
      handle.increment();
    }

    return handle;
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

  private function onlyWhitespace(content : String, from : Int, to : Int) return{
    var sub = content.substr(from, to - from);
    var regex = new EReg("^\\s*$", "");
    return regex.match(sub);
  }
}
