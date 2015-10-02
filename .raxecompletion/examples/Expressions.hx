package examples;using Lambda;using StringTools;class Expressions{

/** 
In Raxe, everything is an expression. You can do
really crazy stuff, but do not get too crazy.
 **/
static dynamic public function main(){
  var enabled = true;

  // Here we will chain some expressions
  var name = function(protected){ return if(protected){
      "Nope";
    }else{
      "John Snow";
    }
  };

  // Simple example on how to use `if` as expression
  var consider = if(enabled){
    "Your name is " + name(false);
  }else{
    "Security issue, response is " + name(true);
  }

  trace(consider);
};
}