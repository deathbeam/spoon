package examples;using Lambda; class ModulesAndInstances {

// You can use self world to reference current class name
static public var instance = new ModulesAndInstances();

// Self keyword before defines basically means that define is static
static public function getInstance(){
  return instance;
};

static public function main(){
  // Get instance of self
  var myInstance = getInstance();

  // Type class name directly
  var myAnotherInstance =new  ModulesAndInstances();

new   ModulesAndInstances().instanceFunction();

  // Call instance function
  myInstance.instanceFunction();
};

public function instanceFunction(){
  trace(this) ;// print this instance to console
  trace(ModulesAndInstances) ;// print this module to console
};}