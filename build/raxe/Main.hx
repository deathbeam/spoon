package raxe;using Lambda;using StringTools;// vim: set ft=rb:

import mcli.Dispatch;
import raxe.cli.Cli;

class Main{

public static function main() return{
  var args = Sys.args();
  Sys.setCwd(args.pop());

  if (args[0] == "-i" || args[0] == "--interp"){
    args = [args.shift(), args.join(" ")];
  }

new   Dispatch(args).dispatch(new Cli());
}

}