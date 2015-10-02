package src.raxe.transpiler;using Lambda;using StringTools;import raxe.tools.StringHandle;

interface Transpiler{

dynamic public function tokens() : Array<String>;
dynamic public function transpile(handle : StringHandle) : String;
}