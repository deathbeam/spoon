package spoon.parser;

import hxparse.Position;
import hxparse.Parser.parse as _;
import hxparse.LexerTokenSource;
import spoon.log.Message;
import spoon.log.Logger;
import spoon.log.LogParser;
import spoon.lexer.Lexer;
import spoon.lexer.Token;
import spoon.parser.Expression;

using StringTools;

class Parser extends hxparse.Parser<LexerTokenSource<Token>, Token> {
  public function new(logParser : LogParser, input:String, sourceName:String) {
    var lexer = new Lexer(byte.ByteData.ofString(input), sourceName);
    var ts = new LexerTokenSource(lexer, Lexer.tok);
    Logger.intialize(logParser, byte.ByteData.ofString(input));
    super(ts);
  }

  public function run() : Expressions  return {
    var v = new Expressions();

    if (Logger.self.catchErrors(function() {
      while(true) _(switch stream {
      case [TEof(_)]: break;
        case [e = parseExpression()]: v.push(e);
      });
    })) v else new Expressions();
  }

  function parseExpression() : Expression return {
    _(switch stream {
      case [e = parseBlock()]: e;
      case [e = parseIf()]: e;
      case [e = parseFor()]: e;
      case [e = parseWhile()]: e;
      case [e = parseConst()]: e;
    });
  }

  function parseConst() : Expression return {
    var v : ConstantDef;
    var p : Position;

    _(switch stream {
      case [TTrue(tp)]: p = tp; v = CBool("true");
      case [TFalse(tp)]: p = tp; v = CBool("false");
      case [TNull(tp)]: p = tp; v = CNull;
      case [TInt(tp, tv)]: p = tp; v = CInt(tv);
      case [TFloat(tp, tv)]: p = tp; v = CFloat(tv);
      case [TString(tp, tv)]: p = tp; v = CString(tv);
      case [TVar(tp, tv)]: p = tp; v = CVar(tv);
      case [TType(tp, tv)]: p = tp; v = CType(tv);
    });

    {
      expr: Constant(v),
      pos: p
    }
  }

  function parseBlock() : Expression return {
    var v = new Expressions();
    var p : Position;

    _(switch stream {
      case [TIndent(tp)]:
        p = tp;

        while(true) switch stream {
          case [TDedent(_) | TEof(_)]: break;
          case [e = parseExpression()]: v.push(e);
        }
    });

    {
      expr: Block(v),
      pos: p
    }
  }

  function parseIf() : Expression return {
    var p : Position;
    var c : Expression;
    var b : Expression;
    var els : Null<Expression> = null;

    _(switch stream {
      case [TIf(tp)]:
        p = tp;
        c = parseExpression();
        b = parseExpression();

        switch stream {
          case [TElse(tp), e = parseExpression()]:
            els = e;
          case _:
        }
    });

    {
      expr: If(c, b, els),
      pos: p
    }
  }

  function parseFor() : Expression return {
    _(switch stream {
      case [TFor(tp)]:
        {
          expr: For(parseExpression(), parseExpression()),
          pos: tp
        }
    });
  }

  function parseWhile() : Expression return {
    _(switch stream {
      case [TWhile(tp)]:
        {
          expr: While(parseExpression(), parseExpression()),
          pos: tp
        }
    });
  }
}
