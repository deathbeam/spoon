package examples;using Lambda;using StringTools;class MultilineStrings{

static public var info = "
  This is multiline string.
  It automatically accepts all tabs, newlines
  and whitespace in general. Syntax for
  multiline strings is triple quotes for initializing,
  triple quotes for terminating
";

static dynamic public function main(){
  trace(info);

  trace("
    And this is inline multiline string.
    It also works.
  ");
};

}