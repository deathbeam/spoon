package spoon.parser;

import hxparse.Position;

typedef Nodes = Array<Node>;

typedef Node = {
  var e : ExpressionDef;
  var p : Position;
}

enum ConstantDef {
  CNull;
  CBool    (v : String);
  CInt     (v : String);
  CFloat   (v : String);
  CString  (v : String);
  CVar     (v : String);
  CType    (v : String);
  CRegexp  (r : String, opt : String);
}

enum ExpressionDef {
  Empty;
  Constant (v : ConstantDef);
  Block    (v : Nodes);
  Params   (v : Nodes);
  Function (?n: Node, ?b : Node, ?p : Node);
  If       (c : Node, b : Node, ?els : Node);
  For      (c : Node, ?b : Node);
  While    (c : Node, ?b : Node);
}
