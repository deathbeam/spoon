package spoon.log;

import byte.ByteData;
import spoon.log.Message;

using StringTools;

typedef LogPosition = {
  var source : String;
  var line : Int;
  var collumn : Int;
}

typedef LogData = {
  var type : String;
  var severity : String;
  @:optional var description : Null<String>;
  @:optional var position : Null<LogPosition>;
}

class LogParserUtil {
  public static var CSON : CsonLogParser = new CsonLogParser();
  public static var JSON : JsonLogParser = new JsonLogParser();
  public static var XML  : XmlLogParser = new XmlLogParser();
  public static var YAML : YamlLogParser = new YamlLogParser();

  public static function fromString(str : String) : LogParser {
    if (str != null) {
      str = str.toLowerCase().replace(" ", "");
    } else {
      str = "";
    }

    return switch(str) {
      case "cson": CSON;
      case "json": JSON;
      case "xml": XML;
      case "yaml", "yml": YAML;
      default: new LogParser();
    }
  }
}

class LogParser {
  var indent = "  ";

  public function new() { }
  public function start() { return ""; }
  public function end() { return ""; }
  public function startMessage() { return ""; }
  public function endMessage() { return ""; }

  public function compile(message : Message, input : ByteData) : LogData {
    var position : Null<LogPosition> = null;

    if (message.position != null) {
      var pos = message.position.getLinePosition(input);
      position = {
        source: message.position.psource,
        line: pos.lineMin,
        collumn: pos.posMin++
      }
    }

    return {
      type: Type.enumConstructor(message.type),
      severity : Type.enumConstructor(message.severity),
      description : message.description,
      position : position
    }
  }

  public function format(data : LogData) : String {
    var result = '${data.severity} : ';

    if (data.position != null) {
      result += '${data.position.source} ${data.position.line}:${data.position.collumn} - ';
    }

    result += data.type;

    if (data.description != null) {
      result += ' ${data.description}';
    }

    return result + "\n";
  }
}

class CsonLogParser extends LogParser {
  public function new() {
    super();
  }

  override public function start() {
    return "[\n";
  }

  override public function end() {
    return "]\n";
  }

  override public function endMessage() {
    return indent + ",\n";
  }

  override public function format(data : LogData) : String {
    var dblindent = indent + indent;
    var trplindent = indent + indent + indent;

    var res =
      '$dblindent"severity": "${data.severity}"\n' +
      '$dblindent"type": "${data.type}"\n';

    if (data.description != null) {
      res += '$dblindent"description": "${data.description}"\n';
    }

    if (data.position != null) {
      res +=
        '$dblindent"position":\n' +
          '$trplindent"source": "${data.position.source}"\n' +
          '$trplindent"line": ${data.position.line}\n' +
          '$trplindent"collumn": ${data.position.collumn}\n';
    }

    return res;
  }
}

class JsonLogParser extends LogParser {
  public function new() {
    super();
  }

  override public function start() {
    return "[\n";
  }

  override public function end() {
    return "]\n";
  }

  override public function startMessage() {
    return indent + "{\n";
  }

  override public function endMessage() {
    return indent + "},\n";
  }

  override public function format(data : LogData) : String {
    var dblindent = indent + indent;
    var trplindent = indent + indent + indent;

    var res =
      '$dblindent"severity": "${data.severity}",\n' +
      '$dblindent"type": "${data.type}"';

    if (data.description != null) {
      res += ',\n$dblindent"description": "${data.description}"';
    }

    if (data.position != null) {
      res +=
        ',\n$dblindent"position": {\n' +
          '$trplindent"source": "${data.position.source}",\n' +
          '$trplindent"line": ${data.position.line},\n' +
          '$trplindent"collumn": ${data.position.collumn}\n' +
        '$dblindent}';
    }

    return res + "\n";
  }
}

class XmlLogParser extends LogParser {
  public function new() {
    super();
  }

  override public function start() {
    return "<xml>";
  }

  override public function end() {
    return "\n</xml>\n";
  }

  override public function startMessage() {
    return '\n$indent<value>\n';
  }

  override public function endMessage() {
    return '$indent<value>';
  }

  override public function format(data : LogData) : String {
    var dblindent = indent + indent;
    var trplindent = indent + indent + indent;

    var res =
      '$dblindent<severity>${data.severity}</severity>\n' +
      '$dblindent<type>${data.type}</type>';

    if (data.description != null) {
      res += '\n$dblindent<description>${data.description}</description>';
    }

    if (data.position != null) {
      res +=
        '\n$dblindent<position>\n' +
          '$trplindent<source>${data.position.source}</source>\n' +
          '$trplindent<line>${data.position.line}</line>\n' +
          '$trplindent<collumn>${data.position.collumn}</collumn>\n' +
        '$dblindent</position>';
    }

    return res + '\n';
  }
}

class YamlLogParser extends LogParser {
  public function new() {
    super();
  }

  override public function start() {
    return "---";
  }

  override public function end() {
    return "\n";
  }

  override public function startMessage() {
    return "\n- ";
  }

  override public function format(data : LogData) : String {
    var dblindent = indent + indent;

    var res =
      'severity: ${data.severity}\n' +
      '${indent}type: ${data.type}\n';

    if (data.description != null) {
      res += '${indent}description: ${data.description}\n';
    }

    if (data.position != null) {
      res +=
        '${indent}position:\n' +
          '${dblindent}source: ${data.position.source}\n' +
          '${dblindent}line: ${data.position.line}\n' +
          '${dblindent}collum: ${data.position.collumn}';
    }

    return res;
  }
}
