package examples;using Lambda; class StaticTyping {

/* 
To define return type, we can add : <YourType>
after method definition
 */
static public function main() : Void{
  var message : String = "Hello World";
  message = toLowerCase(message);

  trace(message);
};

/* 
Also, to define param or variable type,
simply add : <YourType> after it's name
 */
static public function toLowercase(message : String) : String{
  return message.toLowerCase();
};}