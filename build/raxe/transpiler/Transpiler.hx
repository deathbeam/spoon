package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

interface Transpiler{

public function tokens() : Array<String>;
public function transpile(handle : StringHandle) : String;

}