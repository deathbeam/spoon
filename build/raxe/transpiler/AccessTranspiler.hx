package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class AccessTranspiler implements Transpiler{

public function new(){
};

public function tokens() : Array<String> return{
  return [
    "{", "}", "[", "]", "(", ")", "@",
    "//", "/*", "*/", "\"",
    "var", "function", "public", "private",
  ];
};

public function transpile(handle : StringHandle) return{
  var count = -1;
  var notPublic = false;

  while(handle.nextToken()){
    if(handle.is("\"")){
      handle.increment();

      while(handle.nextToken()){
        if(handle.is("\"") && (handle.content.charAt(handle.position -1) != "\\" ||
            (handle.content.charAt(handle.position -1) == "\\" && handle.content.charAt(handle.position -2) == "\\"))){
          break;
        }

        handle.increment();
      }

      handle.increment();
    }else if(handle.is("//") || handle.is("@")){
      handle.increment();
      handle.next("\n");
      handle.increment();
    }else if(handle.is("/*")){
      handle.increment();
      handle.next("*/");
      handle.increment();
    }else if(handle.is("[") || handle.is("{")){
      count = count + 1;
      handle.increment();
    }else if(handle.is("]") || handle.is("}")){
      count = count - 1;
      handle.increment();
    }else if(handle.is("public") || handle.is("private")){
      notPublic = true;
      handle.increment();
    }else if(handle.is("var") || handle.is("function")){
      var current = handle.current;

      if(count == 0 && !notPublic){
        handle.insert("public ");
        handle.increment();
      }

      notPublic = false;
      handle.increment(current);
    }else{
      handle.increment();
    }
  };

  return handle.content;
};

}