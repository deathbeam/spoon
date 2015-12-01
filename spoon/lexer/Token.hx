package spoon.lexer;

import hxparse.Position;

enum Token {
  TEof      (p : Position);
  TPOpen    (p : Position);
  TPClose   (p : Position);
  TComma    (p : Position);
  TDot      (p : Position);
  TIf       (p : Position);
  TElse     (p : Position);
  TFor      (p : Position);
  TWhile    (p : Position);
  TFunction (p : Position);
  TClass    (p : Position);
  TExtends  (p : Position);
  TIndent   (p : Position);
  TDedent   (p : Position);
  TTrue     (p : Position);
  TFalse    (p : Position);
  TNull     (p : Position);
  TComment  (p : Position, v : String);
  TString   (p : Position, v : String);
  TFloat    (p : Position, v : String);
  TInt      (p : Position, v : String);
  TType     (p : Position, v : String);
  TVar      (p : Position, v : String);
}
