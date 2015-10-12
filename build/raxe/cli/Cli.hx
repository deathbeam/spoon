package raxe.cli;using Lambda;using StringTools;// vim: set ft=rb:

import mcli.CommandLine;
import sys.FileSystem;
import raxe.raxefile.Raxefile;
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
  inline public static var ERROR_TYPE = "transpile_error";

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
        this.transpile();
      }else if(FileSystem.exists("Raxefile")){
        var rf =new  Raxefile("Raxefile");
        rf.run(this.task);
      }else{
        this.help();
      }
    }catch(err : String){
      Sys.println(err);
      Sys.exit(0);
    }
  }

  private function transpile() return{
    if(this.src != null){
      if(!FileSystem.exists(src)){
        Error.create(ERROR_TYPE, "Source not found");
      }

      var transpiler =new  TranspilerCommand(this.src, this.dest);
      while(true){
        try{
          if(transpiler.transpile(this.all)){
            if(transpiler.response != null && transpiler.response != ""){
              Sys.println(transpiler.response);
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
