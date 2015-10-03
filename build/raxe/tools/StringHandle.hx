package raxe.tools;using Lambda;using StringTools;// vim: set ft=rb:

class StringHandle{

public var content : String;
public var position : Int;
public var current : String;
public var tokens : Array<String>;

public function new(content : String, ?tokens : Array<String>, position : Int = 0){
  this.content = content;

  if(tokens == null){
    this.tokens = [ "\n" ];
  }else{
    this.tokens = tokens;
  }

  this.position = position;
};

dynamic public function reset(){
  position = 0;
  current = null;
};

dynamic public function atStart() : Bool{
  return position <= 0;
};

dynamic public function atEnd() : Bool{
  return position >= content.length;
};

dynamic public function nearStart(tolerance : Int) : Bool{
  return (position - tolerance) <= 0;
};

dynamic public function nearEnd(tolerance : Int) : Bool{
  return (position + tolerance) >= content.length;
};

dynamic public function closest(content : String) : Bool{
  var divided = divide();
  var regex =new  EReg("[^\\w][ \t]*" + content, "");

  var sub = this.content.substr(position);

  var count = 1;

  while(true){
    if(sub.charAt(count) == " " || sub.charAt(count) == "\t" || sub.charAt(count) == "\n"){
      count = count + 1;
    }else{
      break;
    }
  }

  return regex.match(sub.substr(0, count));
};

dynamic public function is(content : String) : Bool{
  return current == content;
};

dynamic public function isOne(content : Array<String>) : Bool{
  var contains = false;

  for(cnt in content){
    contains = contains || current == cnt;
  }

  return contains;
};

dynamic public function safeisStart(content : String) : Bool{
  var regex =new  EReg("[^\\w]" + content, "");

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
};

dynamic public function safeisEnd(content : String) : Bool{
  var regex =new  EReg(content + "[^\\w]", "");

  if(nearEnd(content.length + 2)){
    return is(content);
  }

  var sub = this.content.substr(
    0,
    nearEnd(content.length + 2) ? content.length : content.length + 2);

  return regex.match(sub);
};

dynamic public function safeis(content : String) : Bool{
  var regex =new  EReg("[^\\w]" + content + "[^\\w]", "");

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
};

dynamic public function at(content : String) : Bool{
  var divided = divide();

  if(divided.right.substr(0, content.length) == content){
    return true;
  }

  return false;
};

dynamic public function prev(?content : String) : Bool{
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
};

dynamic public function next(?content : String) : Bool{
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
};

dynamic public function prevToken() : Bool{
  var newPos = position + 1;
  var currentToken = "";

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
};

dynamic public function prevTokenLine() : Bool{
  var newPos = position + 1;
  var currentToken = "";

  for(token in tokens){
    var pos = this.content.substr(0, position).lastIndexOf(token);

    if(pos != -1 && (pos > newPos || newPos == position + 1)){
      newPos = pos;
      currentToken = token;
    }
  }

  var pos = this.content.substr(0, position).lastIndexOf("\n");

  if(pos != -1 && (pos > newPos || newPos == position + 1)){
    newPos = pos;
    currentToken = "\n";
  }

  if(newPos == -1){
    return false;
  }

  position = newPos;
  current = currentToken;
  return true;
};

dynamic public function nextTokenLine() : Bool{
  var newPos = -1;
  var currentToken = "";

  for(token in tokens){
    var pos = this.content.indexOf(token, position);

    if(pos != -1 && (pos < newPos || newPos == -1)){
      newPos = pos;
      currentToken = token;
    }
  }

  var pos = this.content.indexOf("\n", position);

  if(pos != -1 && (pos < newPos || newPos == -1)){
    newPos = pos;
    currentToken = "\n";
  }

  if(newPos == -1){
    return false;
  }

  position = newPos;
  current = currentToken;
  return true;
};

dynamic public function nextToken() : Bool{
  var newPos = -1;
  var currentToken = "";

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
};

dynamic public function increment(?content : String) : StringHandle{
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
};

dynamic public function decrement(?content : String) : StringHandle{
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
};

dynamic public function insert(?content : String, ?after : Bool) : StringHandle{
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
};

dynamic public function remove(?content : String) : StringHandle{
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
};

private dynamic function divide(?offset: Int = 0){
  return {
    left: position > 0 ? content.substr(0, position + offset) : "",
    right: position < content.length ? content.substring(position + offset) : "",
  };
};

}