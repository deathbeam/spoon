package raxe.cli;using Lambda;using StringTools;import mcli.Dispatch;

/** 
* Entry point for Raxe CLI
 **/
@:tink class Main{
  public static function main() return{
    var args = Sys.args();
    Sys.setCwd(args.pop()) ;

    
    if(args[0] == '-i' || args[0] == '--interp'){
      args = [args.shift(), args.join(' ')];
    }

    
    new Dispatch(args).dispatch(new Cli());
  }
}
