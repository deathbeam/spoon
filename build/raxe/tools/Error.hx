package raxe.tools;using Lambda;using StringTools;/** 
  Error handling
 **/
@:tink class Error{

// Raise a new error formatted into json to be able to parse it everywhere
static dynamic public function create(errorType: String, error: String){
  throw "{\"type\": ${errorType},\"error\": ${error}}";
};
}