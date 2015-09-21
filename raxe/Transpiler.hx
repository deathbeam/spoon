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
    "\"", "=", "(", ")", "\n", "extends", "implements", ".", "/",

    // Raxe keywords
    "--", "require", "module", "def", "end",

    // Haxe keywords
    "//", "import", "var", "function",

    // If, else etc
    "if", "else", "switch", "do", "while",

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
    var buffer : String = null;

    while (handle.nextToken()) {
      if (buffer == "require") {
        if (handle.is("--") || handle.is("require")) {
          buffer = ";";
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
            handle.is("def")) {
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
      } else {
        handle.increment(); // Skip this token
      }
    }

    return this;
  }
}