package spoon.parser;

import hxparse.Position;

typedef Nodes = Array<Node>;

typedef Node = {
  var node : NodeDef;
  var pos : Position;
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

enum NodeDef {
  Empty;
  Constant (v : ConstantDef);
  Block    (v : Nodes);
  Params   (v : Nodes);
  If       (c : Node, b : Node, ?els : Node);
  Else     (b : Node);
  For      (c : Node, ?b : Node);
  While    (c : Node, ?b : Node);
}
