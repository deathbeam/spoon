import sys.io.File;

class Main {
  static function main() {
    var file = File.getContent("export/Main.rx");

    // Ruby end to C-style ending
    var regex = ~/(\s+)end/gm;
    regex.match(file);
    file = regex.replace(file, "$1}");
    
    // Require to import
    regex = ~/^\s*(require)\s"(.+)"$/gm;
    regex.match(file);
    file = regex.replace(file, "import " +  StringTools.replace(regex.matched(2), "/", ".") + ";");

    // Ruby comments to C-like comments
    regex = ~/^(.*)#(\s+.*)$/gm;
    regex.match(file);
    file = regex.replace(file, "$1//$2");

    // Defines to functions and variables
    regex = ~/def(\s*)(static|private|public)?(\s*)([^=\n]*)/g;
    file = regex.map(file, function(r) {
      var type = r.matched(4);

      var result = "";

      if (r.matched(2) != null) {
        result += r.matched(2);
        result += r.matched(3) != null ? r.matched(3) : "";
      }

      // This is function
      var isFunction = type.indexOf("(") > -1;

      if (isFunction) {
        result += "function";
      } else {
        result += "var";
      }

      result += r.matched(1) != null ? r.matched(1) : "";

      return result + type + (isFunction ? " {" : "");
    });

    file += "}";

    File.saveContent("export/Main.hx", file);
  }
}