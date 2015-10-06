package raxe.tools;using Lambda;using StringTools;// vim: set ft=rb:

/** 
  Error handling
 **/
class Error{

// Raise a new error formatted into json to be able to parse it everywhere
static public function create(errorType: String, error: String){
  throw "{\"type\": ${errorType},\"error\": ${error}}";
};

}