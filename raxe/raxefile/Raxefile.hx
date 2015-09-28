package raxe.raxefile;

import raxe.script.RaxeScript;
import sys.io.File;
import sys.FileSystem;

class Raxefile {
  var script : RaxeScript;

  public function new(path : String) {
    script = createScript();
    script.execute(script.parse(File.getContent(path)));
  }

  public function run(task = "default") {
    var fn = script.variables.get(task);
    fn();
  }

  private function createScript() : RaxeScript {
    var script = new RaxeScript();

    script.variables.set("sh", function(cmd : String, ?args : Array<String>) {
      Sys.command(cmd, args);
    });

    script.variables.set("cp", function(from : String, to : String) {
      File.copy(from, to);
    });

    script.variables.set("mv", function(from : String, to : String) {
      FileSystem.rename(from, to);
    });

    script.variables.set("rm", function(path : String) {
      if (FileSystem.isDirectory(path)) {
        FileSystem.deleteDirectory(path);
      } else {
        FileSystem.deleteFile(path);
      }
    });

    return script;
  }
}