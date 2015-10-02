package examples;using Lambda;using StringTools;class StaticTyping{

static public var array : Array<String>;
static public var message : String;

/** 
To define return type, we can add : <YourType>
after method definition
 **/
static dynamic public function main() : Void{
  message = toLowerCase("Hello World");

  trace(message);
};

/** 
Also, to define param or variable type,
simply add : <YourType> after it's name
 **/
static dynamic public function toLowerCase(message : String) : String{
  return message.toLowerCase();
};
}