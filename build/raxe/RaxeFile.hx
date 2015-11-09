package raxe;using Lambda;using StringTools;#if !js
  import sys.io.File;
  import sys.FileSystem;
#end
;
@:tink class RaxeFile{
  public var script : RaxeScript;

  public function new(path : String){
    script = createScript();
    #if js
      script.execute(script.parse(path));
    #else
      script.execute(script.parse(File.getContent(path)));
    #end
  }

  public function run(task : String) return{
    script.variables.get(task)();
  }

  private function createScript() : RaxeScript return{
    var script = new RaxeScript();


    script.variables.set('import', function(thing : String) return{
      var path = thing.replace('.', '/') + '/Raxefile';

      #if !js
        if(FileSystem.exists(path)){
          return script.execute(script.parse(File.getContent(path)));
        }
      #end
;
      path = thing;

      var clazz : Dynamic = Type.resolveClass(path);

      if(clazz == null){
        clazz = Type.resolveEnum(path);

        if(clazz == null){
          trace('Failed to resolve type ' + thing);
        }
      }

      return clazz;
    });

    script.variables.set('echo', function(msg : String) return{
      Sys.println(msg);
    });

    script.variables.set('sh', function(cmd : String, ?args : Array<String> ) return{
      Sys.command(cmd, args);
    });

    script.variables.set('cp', function(from : String, to : String) return{
      File.copy(from, to);
    });

    script.variables.set('mv', function(from : String, to : String) return{
      FileSystem.rename(from, to);
    });

    script.variables.set('rm', function(path : String) return{
      if(FileSystem.isDirectory(path)){
        FileSystem.deleteDirectory(path);
      }else{
        FileSystem.deleteFile(path);
      }
    });

    script.variables.set('env', {
      get: function(key : String) : String return Sys.getEnv(key),
      set: function(key : String, value : String) return Sys.putEnv(key, value),
    });

    return script;
  }
}
