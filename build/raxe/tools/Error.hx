package raxe.tools;using Lambda;using StringTools;// vim: set ft=rb:

/** 
  Error handling
 **/
class Error{
  // Raise a new error formatted into json to be able to parse it everywhere
  public static function create(errorType: String, error: String) return{
    throw("{\"type\": ${errorType},\"error\": ${error}}");
  }
}
