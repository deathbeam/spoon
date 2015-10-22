package raxe.cli;using Lambda;using StringTools;import mcli.CommandLine;
import sys.FileSystem;
import raxe.file.RaxeFile;
import raxe.tools.Error;
import raxe.script.RaxeScript;

/** 
* 8b,dPPYba,  ,adPPYYba,  8b,     ,d8  ,adPPYba,
* 88P'   "Y8  ""     `Y8   `Y8, ,8P'  a8P_____88
* 88          ,adPPPPP88     )888(    8PP"""""""
* 88          88,    ,88   ,d8" "8b,  "8b,   ,aa
* 88          `"8bbdP"Y8  8P'     `Y8  `"Ybbd8"'
*
* Raxe 0.0.1 - https://raxe-lang.org
 **/
class Cli extends CommandLine{
  inline public static var ERROR_TYPE = "compile_error";

  /** 
  * Source directory or file
  * @alias s
   **/
  public var src : String;

  /** 
  * Destination directory or file
  * @alias d
   **/
  public var dest : String;

  /** 
  * Execute the command when source file(s) are changed
  * @alias w
   **/
  public var watch : Bool;

  /** 
  * Copy all (not only .rx) files to dest directory
  * @alias a
   **/
  public var all : Bool;

  /** 
  * Show more info about compilation process
  * @alias v
   **/
  public var verbose : Bool;

  /** 
  * Evaluate Raxe snippet
  * @alias i
   **/
  public var interp : String;

  /** 
  * Execute Raxefile task in this directory (default task is "default")
  * @alias f
   **/
  public function file(task : String = "default") return{
    if(FileSystem.exists("Raxefile")){
      var rf = new RaxeFile("Raxefile");
      rf.run(task);
    }else{
      Sys.println("Raxefile not found in this directory.");
      help();
    }

    Sys.exit(0);
  }

  /** 
  * Show this message
  * @alias h
   **/
  public function help() return{
    Sys.println(this.showUsage());
    Sys.exit(0);
  }

  /** 
  * Default task what is executed when none of above options is matched
   **/
  public function runDefault() return{
    try{
      if(interp != null && interp != ""){
        var script = new RaxeScript();
        Sys.println(script.execute(script.parse(interp)));
      }else if(src != null){
        compile();
      }else{
        help();
      }
    }catch(err : String){
      Sys.println(err);
    }

    Sys.exit(0);
  }

  private function compile() return{
    if(!FileSystem.exists(src)){
      Error.create(ERROR_TYPE, "Source not found");
    }

    var compiler = new CompilerCommand(src, dest, all, verbose);

    while(true){
      try{
        if(compiler.compile()){
          if(compiler.response != null && compiler.response != ""){
            Sys.println(compiler.response);
          }
        }
      }catch(err : String){
        Sys.println(err);
      }

      if(!watch){
        break;
      }
    }
  }
}
