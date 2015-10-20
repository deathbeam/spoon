package raxe.cli;using Lambda;using StringTools;import mcli.Dispatch;

/** 
* Entry point for Raxe CLI
 **/
class Main{
  public static function main() return{
    var args = Sys.args();
    Sys.setCwd(args.pop()) ;// Workaround for correct working directory when running from `haxelib`

    // Workaround for weird quote handling when trying to run command with spaces from CLI
    if(args[0] == "-i" || args[0] == "--interp"){
      args = [args.shift(), args.join(" ")];
    }

    // Execute `mcli` argument dispatcher
    new Dispatch(args).dispatch(new Cli());
  }
}
