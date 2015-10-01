package raxe.transpiler;using Lambda;using StringTools;import raxe.tools.StringHandle;

@:tink class TranspilerGroup{

public var transpilers : Array<Transpiler>;

public function new(){
  transpilers =new  Array<Transpiler>();
};

dynamic public function push(transpiler : Transpiler) : TranspilerGroup{
  transpilers.push(transpiler);
  return this;
};
}