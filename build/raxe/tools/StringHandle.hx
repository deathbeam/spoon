package raxe.tools;using Lambda;using StringTools;class StringHandle{
  public var content : String;
  public var position : Int;
  public var current : String;
  public var tokens : Array<String>;

  public function atStart() : Bool return position <= 0;
  public function atEnd() : Bool return position >= content.length;
  public function nearStart(tolerance : Int) : Bool return (position - tolerance) <= 0;
  public function nearEnd(tolerance : Int) : Bool return (position + tolerance) >= content.length;
  public function is(content : String) : Bool return current == content;

  public function new(content : String, ?tokens : Array<String>, position : Int = 0){
    this.content = content;

    if(tokens == null){
      this.tokens = [ '\n' ];
    }else{
      this.tokens = tokens;
    }

    this.position = position;
  }

  public function reset() return{
    position = 0;
    current = null;
  }

  public function closest(content : String) : Bool return{
    var divided = divide();
    var regex = new EReg('[^\\w][ \t]*' + content, '');

    var sub = this.content.substr(position);

    var count = 1;

    while(true){
      if(sub.charAt(count) == ' ' || sub.charAt(count) == '\t' || sub.charAt(count) == '\n'){
        count = count + 1;
      }else{
        break;
      }
    }

    return regex.match(sub.substr(0, count));
  }

  public function isOne(content : Array<String>) : Bool return{
    var contains = false;

    for(cnt in content){
      contains = contains || current == cnt;
    }

    return contains;
  }

  public function safeisStart(content : String) : Bool return{
    var regex = new EReg('[^\\w]' + content, '');

    if(nearStart(1)){
      return is(content);
    }

    if(nearEnd(content.length + 1)){
      return is(content);
    }

    var sub = this.content.substr(
      nearStart(1) ? position : position - 1,
      nearEnd(content.length + 1) ? content.length : content.length + 1);

    return regex.match(sub);
  }

  public function safeisEnd(content : String) : Bool return{
    var regex = new EReg(content + '[^\\w]', '');

    if(nearEnd(content.length + 2)){
      return is(content);
    }

    var sub = this.content.substr(
      0,
      nearEnd(content.length + 2) ? content.length : content.length + 2);

    return regex.match(sub);
  }

  public function safeis(content : String) : Bool return{
    var regex = new EReg('[^\\w]' + content + '[^\\w]', '');

    if(nearStart(1)){
      return safeisEnd(content);
    }

    if(nearEnd(content.length + 2)){
      return safeisStart(content);
    }

    var sub = this.content.substr(
      nearStart(1) ? position : position - 1,
      content.length + 2);

    return regex.match(sub);
  }

  public function at(content : String) : Bool return{
    var divided = divide();

    if(divided.right.substr(0, content.length) == content){
      return true;
    }

    return false;
  }

  public function prev(?content : String) : Bool return{
    if(content == null){
      if(current != null){
        return prev(current);
      }

      return false;
    }

    var newPos = this.content.substr(0, position).lastIndexOf(content);

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = content;
    return true;
  }

  public function next(?content : String) : Bool return{
    if(content == null){
      if(current != null){
        return next(current);
      }

      return false;
    }

    var newPos = this.content.indexOf(content, position);

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = content;
    return true;
  }

  public function prevToken() : Bool return{
    var newPos = position + 1;
    var currentToken = '';

    for(token in tokens){
      var pos = this.content.substr(0, position).lastIndexOf(token);

      if(pos != -1 && (pos > newPos || newPos == position + 1)){
        newPos = pos;
        currentToken = token;
      }
    }

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = currentToken;
    return true;
  }

  public function prevTokenLine() : Bool return{
    var newPos = position + 1;
    var currentToken = '';

    for(token in tokens){
      var pos = this.content.substr(0, position).lastIndexOf(token);

      if(pos != -1 && (pos > newPos || newPos == position + 1)){
        newPos = pos;
        currentToken = token;
      }
    }

    var pos = this.content.substr(0, position).lastIndexOf('\n');

    if(pos != -1 && (pos > newPos || newPos == position + 1)){
      newPos = pos;
      currentToken = '\n';
    }

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = currentToken;
    return true;
  }

  public function nextTokenLine() : Bool return{
    var newPos = -1;
    var currentToken = '';

    for(token in tokens){
      var pos = this.content.indexOf(token, position);

      if(pos != -1 && (pos < newPos || newPos == -1)){
        newPos = pos;
        currentToken = token;
      }
    }

    var pos = this.content.indexOf('\n', position);

    if(pos != -1 && (pos < newPos || newPos == -1)){
      newPos = pos;
      currentToken = '\n';
    }

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = currentToken;
    return true;
  }

  public function nextToken() : Bool return{
    var newPos = -1;
    var currentToken = '';

    for(token in tokens){
      var pos = this.content.indexOf(token, position);

      if(pos != -1 && (pos < newPos || newPos == -1)){
        newPos = pos;
        currentToken = token;
      }
    }

    if(newPos == -1){
      return false;
    }

    position = newPos;
    current = currentToken;
    return true;
  }

  public function increment(?content : String) : StringHandle return{
    if(content == null){
      if(current != null){
        increment(current);
      }

      return this;
    }

    var newPos = position + content.length;

    if(newPos > this.content.length){
      return this;
    }

    position = newPos;
    current = content;
    return this;
  }

  public function decrement(?content : String) : StringHandle return{
    if(content == null){
      if(current != null){
        decrement(current);
      }

      return this;
    }

    var newPos = position - content.length;

    if(newPos < 0){
      return this;
    }

    position = newPos;
    current = content;
    return this;
  }

  public function insert(?content : String, ?after : Bool) : StringHandle return{
    if(content == null){
      if(current != null){
        insert(current);
      }

      return this;
    }

    var divided;

    if(after == null || !after){
      divided = divide();
    }else{
      divided = divide(1);
    }

    this.content = divided.left + content + divided.right;
    current = content;
    return this;
  }

  public function remove(?content : String) : StringHandle return{
    if(content == null){
      if(current != null){
        remove(current);
      }

      return this;
    }

    var length = content.length;
    var divided = divide();

    if(divided.right.length < length){
      return this;
    }

    this.content = divided.left + divided.right.substr(length);
    current = content;
    return this;
  }

  private function divide(?offset: Int = 0) return{
    {
      left: position > 0 ? content.substr(0, position + offset) : '',
      right: position < content.length ? content.substring(position + offset) : '',
    }
  }
}
