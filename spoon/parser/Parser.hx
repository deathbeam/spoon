package spoon.parser;

import byte.ByteData;
import hxparse.Position;
import hxparse.Parser.parse as _;
import hxparse.LexerTokenSource;
import spoon.log.Message;
import spoon.log.Logger;
import spoon.log.LogParser;
import spoon.lexer.Lexer;
import spoon.lexer.Token;
import spoon.parser.Node;

using StringTools;

class Parser extends hxparse.Parser<LexerTokenSource<Token>, Token> {
  public function new(logParser : LogParser, input:String, sourceName:String) {
    var lexer = new Lexer(ByteData.ofString(input), sourceName);
    var ts = new LexerTokenSource(lexer, Lexer.tok);
    Logger.intialize(logParser, ByteData.ofString(input));
    super(ts);
  }

  public function run() : Nodes  return {
    var v = new Nodes();

    if (Logger.self.catchErrors(function() {
      while(true) _(switch stream {
      case [TEof(_)]: break;
        case [e = parseNode()]: v.push(e);
      });
    })) v else new Nodes();
  }

  function parseNode() : Node return {
    _(switch stream {
      case [e = parseBlock()]: e;
      case [e = parseIf()]: e;
      case [e = parseFor()]: e;
      case [e = parseWhile()]: e;
      case [e = parseConst()]: e;
    });
  }

  function parseConst() : Node return {
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

  function parseBlock() : Node return {
    var v = new Nodes();
    var p : Position;

    _(switch stream {
      case [TIndent(tp)]:
        p = tp;

        while(true) switch stream {
          case [TDedent(_) | TEof(_)]: break;
          case [e = parseNode()]: v.push(e);
        }
    });

    {
      expr: Block(v),
      pos: p
    }
  }

  function parseIf() : Node return {
    var p : Position;
    var c : Node;
    var b : Node;
    var els : Null<Node> = null;

    _(switch stream {
      case [TIf(tp)]:
        p = tp;
        c = parseNode();
        b = parseNode();

        switch stream {
          case [TElse(tp), e = parseNode()]:
            els = e;
          case _:
        }
    });

    {
      expr: If(c, b, els),
      pos: p
    }
  }

  function parseFor() : Node return {
    _(switch stream {
      case [TFor(tp)]:
        {
          expr: For(parseNode(), parseNode()),
          pos: tp
        }
    });
  }

  function parseWhile() : Node return {
    _(switch stream {
      case [TWhile(tp)]:
        {
          expr: While(parseNode(), parseNode()),
          pos: tp
        }
    });
  }
}
