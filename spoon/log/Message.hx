package spoon.log;

import hxparse.Position;

enum MessageSeverity {
  Info;
  Warning;
  Error;
}

enum MessageType {
  Empty;
  NoMatch;
  Unexpected;
  UnterminatedParenthesis;
  UnterminatedString;
  UnterminatedRegExp;
  UnclosedComment;
  UnterminatedEscapeSequence;
  InvalidEscapeSequence;
  UnknownEscapeSequence;
  TabsAndSpaces;
}

typedef Message = {
  var type : MessageType;
  var severity : MessageSeverity;
  @:optional var description : Null<String>;
  @:optional var position : Null<Position>;
}
