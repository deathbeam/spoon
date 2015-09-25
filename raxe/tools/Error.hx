package raxe.tools;

/*
  Error handling
 */
class Error
{
    // Throw a new error formatted into json to be able to parse it everywhere
    public static function create(errorType: String, error: String) {
        throw '{"type": $errorType,"error": $error}';
    }
}
