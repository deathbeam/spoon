package spoon.lexer;

import hxparse.Position;
import hxparse.RuleBuilder;
import spoon.log.Message;
import spoon.log.Logger;
import spoon.log.LogParser;
import spoon.lexer.Token;

class Lexer extends hxparse.Lexer implements RuleBuilder {
  public static var tok = @:rule [
    /***************************************************************************
    * Keywords
    ***************************************************************************/
    "if"
      => TIf(lexer.curPos()),
    "else"
      => TElse(lexer.curPos()),
    "for"
      => TFor(lexer.curPos()),
    "while"
      => TWhile(lexer.curPos()),
    "function"
      => TFunction(lexer.curPos()),
    "class"
      => TClass(lexer.curPos()),
    /***************************************************************************
    * Constants
    ***************************************************************************/
    "true"
      => TTrue(lexer.curPos()),
    "false"
      => TFalse(lexer.curPos()),
    "null"
      => TNull(lexer.curPos()),
    /***************************************************************************
    * Identifiers and types
    ***************************************************************************/
    "_?[A-Z][a-zA-Z\\-]+"
      => TType(lexer.curPos(), lexer.current),
    "_?[a-z][a-zA-Z\\-]+"
      => TVar(lexer.curPos(), lexer.current),
    /***************************************************************************
    * Operators and symbols
    ***************************************************************************/
    "\\("
      => TPOpen(lexer.curPos()),
    "\\)"
      => TPClose(lexer.curPos()),
    ","
      => TComma(lexer.curPos()),
    "\\."
      => TDot(lexer.curPos()),
    ""
      => TEof(lexer.curPos()),
    /***************************************************************************
    * Numbers
    ***************************************************************************/
    "0x[0-9a-fA-F]+"
      => TInt(lexer.curPos(), lexer.current),
    "[0-9]+"
      => TInt(lexer.curPos(), lexer.current),
    "[0-9]+\\.[0-9]+"
      => TFloat(lexer.curPos(), lexer.current),
    "\\.[0-9]+"
      => TFloat(lexer.curPos(), lexer.current),
    "[0-9]+[eE][\\+\\-]?[0-9]+"
      => TFloat(lexer.curPos(), lexer.current),
    "[0-9]+\\.[0-9]*[eE][\\+\\-]?[0-9]+"
      => TFloat(lexer.curPos(), lexer.current),
    /***************************************************************************
    * Strings
    ***************************************************************************/
    '"'
      => TString(process(lexer, string, UnterminatedString), buf.toString()),
    /***************************************************************************
    * Comments
    ***************************************************************************/
    "#[^#][^\n\r]*"
      => lexer.token(tok),
    "###"
      => TComment(process(lexer, comment, UnclosedComment), buf.toString()),
    /***************************************************************************
    * Whitespace skip
    ***************************************************************************/
    "[\r\n\t ]"
      => lexer.token(tok),
    /***************************************************************************
    * Blocks (indent/dedent)
    ***************************************************************************/
    "\n[ \t]*"
      => {
        var last = stack[stack.length - 1];
        var dent = lexer.current.length - 1;

        if (dent > last) {
          stack.push(dent);
          TIndent(lexer.curPos());
        } else if (dent < last) {
          stack.pop();
          TDedent(lexer.curPos());
        } else {
          lexer.token(tok);
        }
      }
  ];

  static function process(lexer, rule, error) {
    buf = new StringBuf();
    var pmin = lexer.curPos();
    var pmax = pmin;

    try {
      pmax = lexer.token(rule);
    } catch (e : haxe.io.Eof) {
      Logger.self.log({
        type: error,
        position: pmin,
        severity: Error
      });
    }

    return Position.union(pmin, pmax);
  }

  static var comment = @:rule [
    "###" => lexer.curPos(),
    "#" => {
      buf.add("#");
      lexer.token(comment);
    },
    "[^#]+" => {
      buf.add(lexer.current);
      lexer.token(comment);
    }
  ];

  static var string = @:rule [
    "\\\\t" => {
      buf.addChar("\t".code);
      lexer.token(string);
    },
    "\\\\n" => {
      buf.addChar("\n".code);
      lexer.token(string);
    },
    "\\\\r" => {
      buf.addChar("\r".code);
      lexer.token(string);
    },
    '\\\\"' => {
      buf.addChar('"'.code);
      lexer.token(string);
    },
    "\\\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]" => {
      buf.add(String.fromCharCode(Std.parseInt("0x" +lexer.current.substr(2))));
      lexer.token(string);
    },
    '"' => {
      lexer.curPos();
    },
    '[^"]' => {
      buf.add(lexer.current);
      lexer.token(string);
    },
  ];

  static var buf: StringBuf;
  static var stack = [0];
}
