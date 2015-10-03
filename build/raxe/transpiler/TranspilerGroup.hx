package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class TranspilerGroup{

public var transpilers : Array<Transpiler>;

public function new(){
  transpilers =new  Array<Transpiler>();
};

dynamic public function push(transpiler : Transpiler) : TranspilerGroup{
  transpilers.push(transpiler);
  return this;
};

}