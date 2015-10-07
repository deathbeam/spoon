package raxe;using Lambda;using StringTools;// vim: set ft=rb:

import mcli.Dispatch;
import raxe.cli.Cli;

class Main{

static public function main() return{
  var args = Sys.args();
  Sys.setCwd(args.pop());
new   Dispatch(args).dispatch(new Cli());
};

}