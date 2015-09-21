package raxe;

import sys.FileSystem;
import sys.io.File;

class Transpiler {
  var currentPackage : String;
  var currentModule : String;
  var inputFile : String;
  var outputFile : String;
  var handle : StringHandle;
  var buffer : String = null;

  var tokens = [
    // Standard keywords
    "\"", "=", "(", ")", "/",

    // Raxe keywords
    "--", "require", "module", "def", "end",

    // Haxe keywords
    //"//", "import", "var", "function", "extends", "implements"

    // If, else etc
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
    handle.insert("package " + currentPackage + ";").increment();
  }

  public function save() {
    File.saveContent(outputFile, handle.content);
  }

  public function transpile() {
    while (handle.nextToken()) {
      if (buffer == "require") {
        if (handle.is("--") || handle.is("require")) {
          handle.insert(";");
          buffer = null;
          continue;
        } else {
          if (handle.is("\"")) {
            handle.remove();
          } else if (handle.is("/")) {
            handle.remove();
            handle.insert(".");
          }

          handle.increment();
          continue;
        }
      } else if (buffer == ";") {
        if (handle.is("require") ||
            handle.is("--") ||
            handle.is("end") ||
            handle.is("def") ||
            handle.is("static") ||
            handle.is("private") ||
            handle.is("public")) {
          handle.insert(";");
          buffer = null;
        }
      }

      // Process comments and ignore everything in
      // them until end of line
      if (handle.is("--")) {
        handle.remove();
        handle.insert("//");
        handle.increment();
        handle.next("\n");
        handle.increment();
      }
      // Step over things in strings (" ")
      else if (handle.is("\"")) {
        handle.increment();
        handle.next("\"");
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
        buffer = "require";
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
          buffer = null;
        } else {
          handle.position = position;
          handle.insert("var");
          buffer = ";";
        }

        handle.increment();
      }
      else if (handle.is("if") || handle.is("while")) {
        handle.increment();
        consumeCurlys();
        handle.insert("{");
        handle.increment();
      }
      else if (handle.is("elsif")) {
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        consumeCurlys();
        handle.insert("{");
        handle.increment();
      }
      else if (handle.is("else")) {
        handle.insert("}");
        handle.increment();
        handle.increment("else");
        handle.insert("{");
        handle.increment();
      }
      else if (handle.is("module")) {
        handle.remove();
        handle.nextToken();

        if (handle.is("enum") ||
            handle.is("class") ||
            handle.is("abstract")) {
          handle.increment();
          handle.insert(" " + currentModule + " ");
        }
      }
      else {
        if (handle.is("(")) consumeCurlys();
        if (handle.next("\n")) {
          handle.insert(";");
          handle.increment("\n;");
        } else {
          handle.increment(); // Skip this token
        }
      }
    }

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