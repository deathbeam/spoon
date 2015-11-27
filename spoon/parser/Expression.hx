package spoon.parser;

import hxparse.Position;

typedef Expressions = Array<Expression>;

typedef Expression = {
  var expr : ExpressionDef;
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

enum ExpressionDef {
  Empty;
  Constant (v : ConstantDef);
  Block    (v : Expressions);
  Params   (v : Expressions);
  If       (c : Expression, b : Expression, elif : Null<Expressions>, el : Null<Expression>);
  ElseIf   (c : Expression, b : Expression);
  Else     (b : Expression);
  For      (c : Expression, b : Expression);
  While    (c : Expression, b : Expression);
}
