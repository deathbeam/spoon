package spoon.parser;

import hxparse.Position;

typedef Expressions = Array<Expression>;

typedef Expression = {
  var expr : ExpressionDef;
  var pos : Position;
}

enum Constant {
  CNull;

  CBool(
    s : String
  );

  CInt(
    v : String
  );

  CFloat(
    f : String
  );

  CString(
    s : String
  );

  CIdent(
    s : String
  );

  CType(
    s : String
  );

  CRegexp(
    r : String,
    opt : String
  );
}

enum ExpressionDef {
  Empty;

  Const(
    value : Constant
  );

  If(
    condition : Expression,
    body : Expression
  );

  Else(
    body : Expression
  );

  For(
    condition : Expression,
    body : Expression
  );

  While(
    condition : Expression,
    body : Expression
  );

  Condition(
    vIf : Expression,
    vElsIf : Null<Expressions>,
    vElse : Null<Expression>
  );

  Block(
    values : Expressions
  );

  Params(
    values : Expressions
  );
}
