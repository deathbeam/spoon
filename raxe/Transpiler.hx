package raxe;

import sys.FileSystem;
import sys.io.File;

class Transpiler {
  var currentPackage : String;
  var currentModule : String;
  var inputFile : String;
  var outputFile : String;
  var handle : StringHandle;

  var tokens = [
    // Standard keywords
    "\"", "\\\"", "(", ")", "/", "=",

    // Raxe keywords
    "-", "require", "module", "def", "end",

    // Haxe keywords
    "extends", "implements", //"//", "import", "var", "function",

    // Expressions
    "if", "else", "case", "elsif", "while",

    // Types
    "class", "enum", "abstract",

    // Access modifiers
    "private", "public", "static"
  ];
  
  public function new(directory : String, inputFile : String, outputFile : String) {
    this.inputFile = inputFile;
    this.outputFile = outputFile;

    currentPackage = StringTools.replace(inputFile, directory, "");
    currentPackage = StringTools.replace(currentPackage, "\\", "/");
    currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".rx", "");
    currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = StringTools.replace(currentPackage, "/", ".");

    handle = new StringHandle(File.getContent(inputFile), tokens);
  }

  public function save() {
    File.saveContent(outputFile, handle.content);
  }

  public function transpile() {
    handle.insert("package " + currentPackage + ";").increment();

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
      // Step over things in strings (" ") and process multiline strings
      else if (handle.is("\"")) {
        if (handle.at("\"\"\"")) {
          handle.remove("\"\"");
        }

        handle.increment();
        handle.next("\"");

        if (handle.at("\"\"\"")) {
          handle.remove("\"\"");
        }

        handle.increment();
      }
      // Change end to classic bracket end
      else if (handle.is("end")) {
        handle.remove();
        handle.insert("}");
        handle.increment();
      }
      // Change require to classic imports
      else if (handle.is("require")) {
        handle.remove();
        handle.insert("import");
        handle.increment();

        while (handle.nextToken()) {
          if (handle.is("-") || handle.is("require")) break;

          if (handle.is("\"")) {
            handle.remove();
          } else if (handle.is("/")) {
            handle.remove();
            handle.insert(".");
          }

          handle.increment();
        }
      }
      // Defines to variables and functions
      else if (handle.is("def")) {
        var position = handle.position;
        handle.remove("def");
        handle.nextToken();

        if (handle.is("(")) {
          handle.position = position;
          handle.insert("function");
          consumeCurlys();
          handle.insert("{");
          handle.increment();
        } else {
          handle.position = position;
          handle.insert("var");
        }

        handle.increment();
      }
      // Insert begin bracket after if and while
      else if (handle.is("if") || handle.is("while")) {
        handle.increment();
        consumeCurlys();
        handle.insert("{");
        handle.increment();
      }
      // Change elsif to else if and insert begin and end brackets around it
      else if (handle.is("elsif")) {
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        consumeCurlys();
        handle.insert("{");
        handle.increment();
      }
      // Inser begin and end brackets around else but do not try to
      // process curlys because there will not be any
      else if (handle.is("else")) {
        handle.insert("}");
        handle.increment();
        handle.increment("else");
        handle.insert("{");
        handle.increment();
      }
      // Process module declarations and insert curly after them
      else if (handle.is("module")) {
        handle.remove();

        while(handle.nextToken()) {
          if (handle.is("enum") ||
              handle.is("class") ||
              handle.is("abstract")) {
            handle.increment();
            handle.insert(" " + currentModule + " ");
            handle.increment();
          } else if (handle.is("extends") || handle.is("implements")) {
            handle.increment();
          } else {
            handle.insert("{");
            break;
          }
        }
      }
      else {
        handle.increment(); // Skip this token
      }
    }

    handle.content = handle.content + "}";

    return this;
  }

  private function consumeCurlys() {
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