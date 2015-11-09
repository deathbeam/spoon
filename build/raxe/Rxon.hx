package raxe;using Lambda;using StringTools;import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import raxe.compiler.Compiler;

@:tink class Rxon{
  public var interp : Interp = new Interp();
  public var parser : Parser = new Parser();
  public var compiler : Compiler = new Compiler(true);
  public function new()  null;

  public function parse(s : String) : Map<String, Dynamic> return{
    var content = compiler.compileString('return ${s}');
    interp.execute(parser.parseString(content));
  }
}
