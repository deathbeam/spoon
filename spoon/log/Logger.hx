package spoon.log;

import byte.ByteData;
import spoon.log.Message;
import spoon.log.LogParser;

class Logger {
  public static var self : Logger;

  public static function intialize(parser : LogParser, source : ByteData) {
    self = new Logger(parser, source);
  }

  var parser : LogParser;
  var source : ByteData;
  var messages = new Array<Message>();

  public function new(parser : LogParser, source : ByteData) {
    this.parser = parser;
    this.source = source;
  }

  public function log(m : Message) {
    messages.push(m);
  }

  public function dump() {
    var res = "";
    var fatal = false;

    if (messages.length > 0) {
      res = parser.start();
      for (message in messages) {
        if (message.severity == Error) {
          fatal = true;
        }

        res += parser.startMessage();
        res += parser.format(parser.compile(message, source));
        res += parser.endMessage();
      }

      res += parser.end();
    }

    if (res.length > 0) {
      Sys.print(res);
    }

    if (fatal) {
      Sys.exit(1);
    }
  }
}
