package examples;using Lambda;using StringTools;class Errors{

static dynamic public function main(){
  try{
    throw "Error";
  }catch(msg : String){
    trace("Error occurred: ${msg}");
  }
};
}