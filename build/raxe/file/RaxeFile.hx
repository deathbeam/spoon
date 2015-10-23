package raxe.file;using Lambda;using StringTools;import raxe.script.RaxeScript;
import sys.io.File;
import sys.FileSystem;

class RaxeFile{
  public var script : RaxeScript;

  public function new(path : String){
    script = createScript();
    script.execute(script.parse(File.getContent(path)));
  }

  public function run(task : String) return{
    script.variables.get(task)();
  }

  public function createScript() : RaxeScript return{
    var script = new RaxeScript();

    script.variables.set("echo", function(msg : String) return{
      Sys.println(msg);
    });

    script.variables.set("sh", function(cmd : String, ?args : Array<String>) return{
      Sys.command(cmd, args);
    });

    script.variables.set("cp", function(from : String, to : String) return{
      File.copy(from, to);
    });

    script.variables.set("mv", function(from : String, to : String) return{
      FileSystem.rename(from, to);
    });

    script.variables.set("rm", function(path : String) return{
      if(FileSystem.isDirectory(path)){
        FileSystem.deleteDirectory(path);
      }else{
        FileSystem.deleteFile(path);
      }
    });

    script.variables.set("env", {
      get: function(key : String) : String return Sys.getEnv(key),
      set: function(key : String, value : String) return Sys.putEnv(key, value),
    });

    return script;
  }
}
