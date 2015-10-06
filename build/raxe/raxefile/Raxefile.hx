package raxe.raxefile;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.script.RaxeScript;
import sys.io.File;
import sys.FileSystem;

class Raxefile{

public var script : RaxeScript;

public function new(path : String){
  script = createScript();
  script.execute(script.parse(File.getContent(path)));
};

public function run(task : String){
  var fn = script.variables.get(task);
  fn();
};

public function createScript() : RaxeScript{
  var script =new  RaxeScript();

  script.variables.set("sh", function(cmd : String, ?args : Array<String>){
    Sys.command(cmd, args);
  });

  script.variables.set("cp", function(from : String, to : String){
    File.copy(from, to);
  });

  script.variables.set("mv", function(from : String, to : String){
    FileSystem.rename(from, to);
  });

  script.variables.set("rm", function(path : String){
    if(FileSystem.isDirectory(path)){
      FileSystem.deleteDirectory(path);
    }else{
      FileSystem.deleteFile(path);
    }
  });

  script.variables.set("env", {
    get: function(key : String){
      return Sys.getEnv(key);
    },
    set: function(key : String, value : String){
      Sys.putEnv(key, value);
    },
  });

  return script;
};

}