package raxe.raxefile;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.script.RaxeScript;
import sys.io.File;
import sys.FileSystem;

class Raxefile{
  public var script : RaxeScript;

  public function new(path : String){
    script = createScript();
    script.execute(script.parse(File.getContent(path)));
  }

  public function run(task : String) return{
    var fn = script.variables.get(task);
    fn();
  }

  public function createScript() : RaxeScript return{
    var script =new  RaxeScript();

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
      get: function(key : String) return{
        return Sys.getEnv(key);
      },
      set: function(key : String, value : String) return{
        Sys.putEnv(key, value);
      },
    });

    return script;
  }
}
