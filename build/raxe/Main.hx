package raxe;using Lambda;using StringTools;import mcli.Dispatch;
import raxe.cli.Cli;

class Main{

static dynamic public function main(){
  var args = Sys.args();
  Sys.setCwd(args.pop());
new   Dispatch(args).dispatch(new Cli());
};
}