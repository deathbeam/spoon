package export;using Lambda; class Main 

{/* 
To define return type, we can add : <YourType>
after method definition
 */
static public function main(){ : Void;
  var message : String = "Hello World";
  message = toLowerCase(message);

  trace(message);
};

/* 
Also, to define param or variable type,
simply add : <YourType> after it's name
 */
static public var toLowercase(message : String) : String;
  return message.toLowerCase();
}}