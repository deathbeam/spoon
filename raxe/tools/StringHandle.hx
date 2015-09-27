package raxe.tools;

class StringHandle {
  public var content : String;
  public var position : Int;
  public var current : String;
  public var tokens : Array<String>;

  public function new(content : String, ?tokens : Array<String>, position : Int = 0) {
    this.content = content;

    if (tokens == null) {
      this.tokens = [ "\n" ];
    } else {
      this.tokens = tokens;
    }
    
    this.position = position;
  }

  public function reset() {
    position = 0;
    current = null;
  }

  public function atStart() : Bool {
    return position <= 0;
  }

  public function atEnd() : Bool {
    return position >= content.length;
  }

  public function nearStart(tolerance : Int) : Bool {
    return (position - tolerance) <= 0;
  }

  public function nearEnd(tolerance : Int) : Bool {
    return (position + tolerance) >= content.length;
  }

  public function is(content : String) : Bool {
    return current == content;
  }

  public function safeisStart(content : String) : Bool {
    var regex = new EReg("[^\\w]" + content, "");

    if (nearStart(1)) {
      return is(content);
    }

    if (nearEnd(content.length + 1)) {
      return is(content);
    }

    var sub = this.content.substr(
      nearStart(1) ? position : position - 1,
      nearEnd(content.length + 1) ? content.length : content.length + 1);

    return regex.match(sub);
  }

  public function safeisEnd(content : String) : Bool {
    var regex = new EReg(content + "[^\\w]", "");

    if (nearEnd(content.length + 2)) {
      return is(content);
    }

    var sub = this.content.substr(
      0,
      nearEnd(content.length + 2) ? content.length : content.length + 2);

    return regex.match(sub);
  }

  public function safeis(content : String) : Bool {
    var regex = new EReg("[^\\w]" + content + "[^\\w]", "");

    if (nearStart(1)) {
      return safeisEnd(content);
    }

    if (nearEnd(content.length + 2)) {
      return safeisStart(content);
    }

    var sub = this.content.substr(
      nearStart(1) ? position : position - 1,
      content.length + 2);

    return regex.match(sub);
  }

  public function at(content : String) : Bool {
    var divided = divide();
    if (divided.right.substr(0, content.length) == content) return true;
    return false;
  }

  public function prev(?content : String) : Bool {
    if (content == null) {
      if (current != null) return prev(current);
      return false;
    }

    var newPos = this.content.substr(0, position).lastIndexOf(content);
    if (newPos == -1) return false;
    position = newPos;
    current = content;
    return true;
  }

  public function next(?content : String) : Bool {
    if (content == null) {
      if (current != null) return next(current);
      return false;
    }

    var newPos = this.content.indexOf(content, position);
    if (newPos == -1) return false;
    position = newPos;
    current = content;
    return true;
  }

  public function prevToken() : Bool {
    var newPos = position + 1;
    var currentToken = "";

    for (token in tokens) {
      var pos = this.content.substr(0, position).lastIndexOf(token);

      if (pos != -1 && (pos > newPos || newPos == position + 1)) {
        newPos = pos;
        currentToken = token;
      }
    }

    if (newPos == -1) return false;
    position = newPos;
    current = currentToken;
    return true;
  }

  public function prevTokenLine() : Bool {
    var newPos = position + 1;
    var currentToken = "";

    for (token in tokens) {
      var pos = this.content.substr(0, position).lastIndexOf(token);

      if (pos != -1 && (pos > newPos || newPos == position + 1)) {
        newPos = pos;
        currentToken = token;
      }
    }

    var pos = this.content.substr(0, position).lastIndexOf("\n");

    if (pos != -1 && (pos > newPos || newPos == position + 1)) {
      newPos = pos;
      currentToken = "\n";
    }

    if (newPos == -1) return false;
    position = newPos;
    current = currentToken;
    return true;
  }

  public function nextTokenLine() : Bool {
    var newPos = -1;
    var currentToken = "";

    for (token in tokens) {
      var pos = this.content.indexOf(token, position);

      if (pos != -1 && (pos < newPos || newPos == -1)) {
        newPos = pos;
        currentToken = token;
      }
    }

    var pos = this.content.indexOf("\n", position);

    if (pos != -1 && (pos < newPos || newPos == -1)) {
      newPos = pos;
      currentToken = "\n";
    }

    if (newPos == -1) return false;
    position = newPos;
    current = currentToken;
    return true;
  }

  public function nextToken() : Bool {
    var newPos = -1;
    var currentToken = "";

    for (token in tokens) {
      var pos = this.content.indexOf(token, position);

      if (pos != -1 && (pos < newPos || newPos == -1)) {
        newPos = pos;
        currentToken = token;
      }
    }

    if (newPos == -1) return false;
    position = newPos;
    current = currentToken;
    return true;
  }

  public function increment(?content : String) : StringHandle {
    if (content == null) {
      if (current != null) increment(current);
      return this;
    }

    var newPos = position + content.length;
    if (newPos > this.content.length) return this;
    position = newPos;
    current = content;
    return this;
  }

  public function decrement(?content : String) : StringHandle {
    if (content == null) {
      if (current != null) decrement(current);
      return this;
    }

    var newPos = position - content.length;
    if (newPos < 0) return this;
    position = newPos;
    current = content;
    return this;
  }

  public function insert(?content : String) : StringHandle {
    if (content == null) {
      if (current != null) insert(current);
      return this;
    }

    var divided = divide();

    this.content = divided.left + content + divided.right;
    current = content;
    return this;
  }

  public function remove(?content : String) : StringHandle {
    if (content == null) {
      if (current != null) remove(current);
      return this;
    }

    var length = content.length;
    var divided = divide();

    if (divided.right.length < length) return this;
    this.content = divided.left + divided.right.substr(length);
    current = content;
    return this;
  }

  private function divide() {
    return {
      left: position > 0 ? content.substr(0, position) : "",
      right: position < content.length ? content.substring(position) : ""
    }
  }
}