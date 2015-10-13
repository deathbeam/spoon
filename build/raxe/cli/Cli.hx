package raxe.cli;using Lambda;using StringTools;import mcli.CommandLine;
import sys.FileSystem;
import raxe.file.RaxeFile;
import raxe.tools.Error;
import raxe.script.RaxeScript;

/** 
8b,dPPYba,  ,adPPYYba,  8b,     ,d8  ,adPPYba,
88P'   "Y8  ""     `Y8   `Y8, ,8P'  a8P_____88
88          ,adPPPPP88     )888(    8PP"""""""
88          88,    ,88   ,d8" "8b,  "8b,   ,aa
88          `"8bbdP"Y8  8P'     `Y8  `"Ybbd8"'

Raxe 0.0.1 - https://raxe-lang.org
 **/
class Cli extends CommandLine{
  inline public static var ERROR_TYPE = "compile_error";

  /** 
  Source directory or file
  @alias s
   **/
  public var src : String;

  /** 
  Destination directory or file
  @alias d
   **/
  public var dest : String;

  /** 
  Task to execute when running Raxefile
  @alias t
   **/
  public var task : String = "default";

  /** 
  Execute the command when source file(s) are changed
  @alias w
   **/
  public var watch : Bool;

  /** 
  Copy all (not only .rx) files to dest directory
  @alias a
   **/
  public var all: Bool;

  /** 
  Evaluate Raxe snippet
  @alias i
   **/
  public var interp: String;

  /** 
  Show this message
  @alias h
   **/
  public function help() return{
    Sys.println(this.showUsage());
    Sys.exit(0);
  }

  public function runDefault() return{
    try{
      if(interp != null && interp != ""){
        var script =new  RaxeScript();
        Sys.println(script.execute(script.parse(interp)));
      }else if(this.src != null){
        this.compile();
      }else if(FileSystem.exists("Raxefile")){
        var rf =new  RaxeFile("Raxefile");
        rf.run(this.task);
      }else{
        this.help();
      }
    }catch(err : String){
      Sys.println(err);
      Sys.exit(0);
    }
  }

  private function compile() return{
    if(this.src != null){
      if(!FileSystem.exists(src)){
        Error.create(ERROR_TYPE, "Source not found");
      }

      var compiler =new  CompilerCommand(this.src, this.dest);
      while(true){
        try{
          if(compiler.compile(this.all)){
            if(compiler.response != null && compiler.response != ""){
              Sys.println(compiler.response);
            }
          }
        }catch(err : String){
          Sys.println(err);
        }

        if(!this.watch){
          break;
        }
      }
    }

    Sys.exit(0);
  }
}
