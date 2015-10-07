package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class AccessTranspiler implements Transpiler{

public function new(){
};

public function tokens() : Array<String> return{
  return [
    "{", "}", "[", "]", "(", ")", "@",
    "//", "/*", "*/", "\"",
    "var", "function", "public", "private", "module", "new",
  ];
};

public function transpile(handle : StringHandle) return{
  var count = -1;
  var isPrivate = false;
  var isStatic = false;

  while(handle.nextToken()){
    if(handle.safeis("module")){
      handle.remove();
      handle.insert("class");
      handle.increment();
      isStatic = true;
    }else if(handle.is("\"")){
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
    }else if(handle.safeis("public") || handle.safeis("private")){
      isPrivate = true;
      handle.increment();
    }else if(handle.safeis("var") || handle.safeis("function")){
      var current = handle.current;

      if(count == 0){
        if(!isPrivate){
          handle.insert("public ");
          handle.increment();
        }

        if(isStatic){
          var position = handle.position;
          handle.nextToken();
          handle.position = position;

          if(!handle.safeis("new")){
            handle.insert("static ");
            handle.increment();
          }
        }
      }

      isPrivate = false;
      handle.increment(current);
    }else{
      handle.increment();
    }
  };

  return handle.content;
};

}