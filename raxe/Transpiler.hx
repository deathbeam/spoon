package raxe;

interface Transpiler {
  public function tokens() : Array<String>;
  public function transpile(handle : StringHandle, packagepath : String, name : String) : String;
}