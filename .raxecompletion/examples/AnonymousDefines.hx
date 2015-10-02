package examples;using Lambda;using StringTools;class AnonymousDefines{

/** 
Anonymous array declaration is not dynamic by default.
You can have array of only one type.
 **/
static public var array = [
  "a", "b", "c",
];

/** 
Anonymous maps, not dynamic by default too
 **/
static public var map = [
  "a" => function(test){
    trace(test);
  },
];

/** 
And this is dynamic anonymous array, so you can put anything in there
 **/
static public var dynarray : Array<Dynamic> = [
  "a", "b", "c", 6, 7, array,
];

/** 
Same applies to anonymous structures.
 **/
static public var struct = {
  a: "hello",
  b: "yolo",
  callback: function(event){
    return event + " World";
  },
};

static dynamic public function main(){
  // Here we will call our anonymous function
  var result = struct.callback("Hello");

  // And now, print everything to console
  trace(result);
  trace(dynarray);
  trace(map);
  trace(array);
  trace(struct);
};

}