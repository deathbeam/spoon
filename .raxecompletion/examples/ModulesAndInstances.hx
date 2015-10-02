package examples;using Lambda;using StringTools;class ModulesAndInstances{

// You can use self world to reference current class name
static public var instance = new ModulesAndInstances();

// Self keyword before defines basically means that define is static
static dynamic public function getInstance(){
  return instance;
};

static dynamic public function main(){
  // Get instance of self
  var myInstance = getInstance();

  // Type class name directly
  var myAnotherInstance =new  ModulesAndInstances();

new   ModulesAndInstances().instanceFunction();

  // Call instance function
  myInstance.instanceFunction();
};

// Create the constructor method so we can make instances
public function new(){
  trace("Instance created");
};

dynamic public function instanceFunction(){
  trace(this) ;// print this instance to console
  trace(ModulesAndInstances.) ;// print this module to console
};

}