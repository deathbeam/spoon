package raxe.compiler;using Lambda;using StringTools;import raxe.tools.StringHandle;
#if !js
  import sys.io.File;
#end

/** 
* The most important Raxe class, which compiles Raxe source to Haxe source
 **/
@:tink class Compiler{
  private var fileName : String = '';
  private var currentName : String = '';
  private var currentType : String = '';
  private var currentExpression : String = '';
  private var hasVisibility : Bool = false;
  private var opened : Int = -1;
  private var currentOpened : Int = -1;
  private var script : Bool = false;

  /** 
  * Array of tokens used for StringHandle to correctly parse Raxe files
   **/
  public var tokens = [
    // Line break
    '\n', ';',

    // Whitespace skip
    '#', '@new', '@@', '@', '"', '\'', '$$', '/',

    // Types
    '::', 'class', 'enum', 'abstract', 'trait', 'interface',

    // Modifiers
    'public', 'private',

    // Special keywords
    'import', 'def', 'new', 'end', 'do', 'typedef', 'try', 'catch', 'void',

    // Brackets
    '{', '}', '(', ')', '[', ']',

    // Word operators
    'isnt', 'is', 'and', 'or', 'not',

    // Operators (< is also used for inheritance)
    ':', '?', '=', '+', '-', '*', '.', '/', ',' , '|', '&',  '^', '%', '<', '>', '~',

    // Expressions
    'elsif', 'if', 'else', 'while', 'for', 'switch', 'when',
  ];

  /** 
  * Create new instance of Raxe compiler
  * @param script Specify if it is RaxeScript or Raxe compiler (default false)
   **/
  public function new(script : Bool = false){
    this.script = script;
  }

  #if !js
    /** 
    * Compile Raxe file and returns Haxe result
    * @param directory root project directory, needed for correct package names
    * @param file file path to compile
    * @return Raxe file compiled to it's Haxe equivalent
     **/
    public function compileFile(directory : String, file : String) : String return{
      var currentPackage = file
        .replace(directory, '')
        .replace('\\', '/');

      fileName = currentPackage
        .substr(currentPackage.lastIndexOf('/') + 1)
        .replace('.rx', '');

      currentName = fileName;

      currentPackage = currentPackage
        .replace(currentPackage.substr(currentPackage.lastIndexOf('/')), '')
        .replace('/', '.');

      if(currentPackage.charAt(0) == '.'){
        currentPackage = currentPackage.substr(1);
      }

      run(new StringHandle(File.getContent(file), tokens)
        .insert('package ' + currentPackage + ';using Lambda;using StringTools;')
        .increment()
      ).content;
    }
  #end

  /** 
  * Compile Raxe code and returns Haxe result
  * @param code Raxe source code
  * @return Raxe code compiled to it's Haxe equivalent
   **/
  public function compileString(code : String) return{
    run(new StringHandle(code,tokens)).content;
  }

  /** 
  * Process content of StringHandle and return it modified
  * @param script Determine if automatically insert package and class names
  * @param handle Handle with initial content and position
  * @return modified string handle with adjusted position and content
   **/
  public function run(handle : StringHandle) : StringHandle return{
    while(handle.nextToken()){
      process(handle);
    }

    return handle;
  }

  /** 
  * Process single token of StringHandle and return it modified
  * @param script Determine if automatically insert package and class names
  * @param handle Handle with initial content and position
  * @return modified string handle with adjusted position and content
   **/
  private function process(handle : StringHandle) : StringHandle return{
    // Skip compiler defines and annotations
    if(handle.match('$$') && handle.at('$$[')){
      handle.remove();
      handle.insert('@');
      handle.increment();
      consumeBrackets(handle, '[', ']', '', '');
      safeNextToken(handle);

      if(handle.match('\n')){
        handle.increment();
      }
    }else if(handle.match('@@')){
      if(handle.safeMatch('@@')){
        handle.remove();
        handle.insert(currentName);
      }else{
        handle.remove();
        handle.insert(currentName + '.');
      }

      handle.increment();
    }else if(handle.match('~') && handle.at('~/')){
      handle.increment('~/');

      while(handle.nextToken()){
        if(handle.match('/') && isNotEscaped(handle)){
          handle.increment();
          break;
        }

        handle.increment();
      }
    }else if(handle.match('@')){
      if(handle.safeMatch('@')){
        handle.remove();
        handle.insert('this');
        handle.increment();
      }else if(handle.at('@[')){
        consumeGenerics(handle);
      }else{
        handle.remove();
        handle.insert('this.');
        handle.increment();
      }
    // Step over things in strings (" ") and process multiline strings
    }else if(handle.match('"')){
      consumeStrings(handle);
    // Correct access
    }else if(handle.safeMatch('public') || handle.safeMatch('private')){
      hasVisibility = true;
      handle.increment();
    // Change require to classic imports
    }else if(handle.safeMatch('import')){
      handle.next('\n');
      handle.insert(';');
      handle.increment();
    // Empty operator (null)
    }else if(handle.safeMatch('void')){
      handle.remove();
      handle.insert('(function(){})()');
      handle.increment();
    // Structures and arrays
    }else if(handle.match('{')){
      opened = opened + 1;
      consumeTables(handle);
      opened = opened - 1;
    }else if(handle.match('[')){
      opened = opened + 1;
      consumeBrackets(handle, '[', ']');
      opened = opened - 1;
    // Change end to classic bracket end
    }else if(handle.safeMatch('end')){
      handle.remove();
      handle.insert('}');
      handle.increment();
      opened = opened - 1;

      if(currentOpened == opened){
        currentOpened = -1;
        currentExpression = '';
      }

      if(opened == -1){
        currentType = '';
      }
    // Insert begin bracket after switch
    }else if(handle.safeMatch('switch')){
      currentExpression = handle.current;
      currentOpened = opened;
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
      opened = opened + 1;
    // Replaced when with Haxe "case"
    }else if(handle.safeMatch('when')){
      handle.remove();
      handle.insert('case');
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert(':');
      handle.increment();
    // Insert begin bracket after try
    }else if(handle.safeMatch('try')){
      handle.increment();
      handle.insert('{');
      handle.increment();
      opened = opened + 1;
    // Insert brackets around catch
    }else if(handle.safeMatch('catch')){
      handle.insert('}');
      handle.increment();
      handle.increment('catch');
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
    // Insert begin bracket after if and while
    }else if(handle.safeMatch('if')){
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
      opened = opened + 1;
    // Change elseif to else if and insert begin and end brackets around it
    }else if(handle.safeMatch('elsif')){
      handle.remove();
      handle.insert('}else if');
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
    // Insert begin brackets after loops declaration
    }else if(handle.safeMatch('while') || handle.safeMatch('for')){
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      opened = opened + 1;
      handle.increment();
    // Inser begin and end brackets around else but do not try to
    // process curlys because there will not be any
    }else if(handle.safeMatch('else')){
      if(currentExpression == 'switch'){
        handle.remove();
        handle.insert('default:');
      }else{
        handle.insert('}');
        handle.increment();
        handle.increment('else');
        handle.insert('{');
      }

      handle.increment();
    // Defines to variables and functions
    }else if(handle.safeMatch('def')){
      handle.remove('def');

      var position = handle.position;

      if(opened == 0 && !script){
        if(!hasVisibility){
          handle.insert('public ');
          handle.increment();
        }

        position = handle.position;
        safeNextToken(handle);

        if(handle.match('@new')){
          handle.remove();
          handle.insert('static var __new = (function(){_new(); return true;})(); static  _new');
          handle.increment();
          position = handle.position - 5;
        }else if(handle.match('@')){
          handle.remove();
          handle.position = position;
          handle.insert('static ');
          handle.increment();
          position = handle.position;
          safeNextToken(handle);
        }
      }

      hasVisibility = false;
      safeNextToken(handle);

      var implicit = true;

      if(handle.safeMatch('new')){
        implicit = false;
        handle.increment();
        handle.nextToken();
      }

      if(handle.match('@')){
        consumeGenerics(handle);
        handle.nextToken();
      }

      if(handle.match('(')){
        handle.position = position;
        handle.insert('function');
        consumeBrackets(handle, '(', ')');

        while(safeNextToken(handle)){
          if(handle.match('do')){
            handle.remove();

            if(implicit){
              handle.insert('return');
            }

            break;
          }else if(handle.matchOne(['\n', '#', ';'])){
            if(handle.match(';')){
              handle.remove();
            }

            if(implicit){
              handle.insert(' return{');
            }else{
              handle.insert('{');
            }

            handle.increment();
            opened = opened + 1;
            break;
          }else{
            process(handle);
          }
        }
      }else{
        handle.position = position;
        handle.insert('var');
        handle.increment();
      }
    // Closures and blocks
    }else if(handle.safeMatch('do')){
      handle.remove('do');
      handle.insert('{');
      opened = opened + 1;
      handle.increment();
    // [abstract] class/trait/enum
    }else if (handle.safeMatch('class') || handle.safeMatch('trait') || handle.safeMatch('enum') || handle.safeMatch('interface') || handle.safeMatch('abstract')){
      currentType = handle.current;

      if(currentType != 'enum' && currentType != 'interface'){
        handle.insert('@:tink ');
        handle.increment();
      }

      if(currentType == 'trait'){
        handle.remove('trait');
        handle.insert('interface');
        handle.increment();
      }else{
        handle.increment(currentType);
      }

      var position = handle.position;
      var nameSet = false;

      while(safeNextToken(handle)){
        if(handle.match('@')){
          if(!nameSet){
            currentName = fileName;
            nameSet = true;
          }

          if(handle.at('@[')){
            consumeGenerics(handle);

            if(handle.match(';')){
              handle.remove(';');

              var position = handle.position;
              handle.nextToken();

              if(handle.match('\n')){
                handle.insert('{');
                handle.increment();
                opened += 1;
                break;
              }else{
                handle.position = position;
              }
            }
          }else{
            handle.remove();
            handle.insert(currentName);
          }
        }else if(handle.match('<')){
          if(!nameSet){
            currentName = handle.content.substr(position, handle.position - position);
            nameSet = true;
          }

          handle.remove();
          handle.insert('extends');
        }else if(handle.match('::')){
          if(!nameSet){
            currentName = handle.content.substr(position, handle.position - position);
            nameSet = true;
          }

          handle.remove();
          handle.insert('implements');
        }else if(handle.match('\n')){
          if(!nameSet){
            currentName = handle.content.substr(position, handle.position - position);
            nameSet = true;
          }

          handle.insert('{');
          handle.increment();
          opened += 1;
          break;
        }

        handle.increment();
      }
    // Process comments and newlines. Also, insert semicolons when needed
    }else if(handle.match('\n') || handle.match('#')){
      consumeEndOfLine(handle, ';');
    // Word operators
    }else if(handle.safeMatch('is')){
      handle.remove();
      handle.insert('==');
      handle.increment();
    }else if(handle.safeMatch('isnt')){
      handle.remove();
      handle.insert('!=');
      handle.increment();
    }else if(handle.safeMatch('and')){
      handle.remove();
      handle.insert('&&');
      handle.increment();
    }else if(handle.safeMatch('or')){
      handle.remove();
      handle.insert('||');
      handle.increment();
    }else if(handle.safeMatch('not')){
      handle.remove();
      handle.insert('!');
      handle.increment();
    // Skip this token
    }else{
      handle.increment();
    }

    return handle;
  }

  private function safeNextToken(handle : StringHandle) : Bool return{
    handle.nextToken();

    if(safeCheck(handle, 'def') && safeCheck(handle, 'if') && safeCheck(handle, 'elsif') && safeCheck(handle, 'end')  &&
        safeCheck(handle, 'while') && safeCheck(handle, 'for') && safeCheck(handle, 'import') &&
        safeCheck(handle, 'do') && safeCheck(handle, 'else') && safeCheck(handle, 'try') && safeCheck(handle, 'catch') &&
        safeCheck(handle, 'private') && safeCheck(handle, 'public') && safeCheck(handle, 'void') && safeCheck(handle, 'switch') &&
        safeCheck(handle, 'when') && safeCheck(handle, 'is') && safeCheck(handle, 'isnt') && safeCheck(handle, 'and') &&
        safeCheck(handle, 'or') && safeCheck(handle, 'not')){
      return true;
    }else{
      handle.increment();
      return safeNextToken(handle);
    }
  }

  private function safeCheck(handle : StringHandle, content : String) : Bool return{
    if(handle.match(content)){
      return handle.safeMatch(content);
    }

    return true;
  }

  private function consumeCondition(handle : StringHandle, condition : String) return{
    handle.increment();
    handle.insert('(');
    handle.increment();

    var curLevel = opened;

    while(handle.nextToken()){
      if(curLevel == opened && (handle.match('\n') || handle.match('#'))){
        if(consumeEndOfLine(handle, '){')){
          break;
        }
      }else{
        process(handle);
      }
    }
  }

  private function consumeBrackets(handle : StringHandle, startSymbol : String, endSymbol : String, startReplace : String = null, endReplace : String = null, doProcess : Bool = true) return{
    var count = 0;
    var startPosition = handle.position;

    while(handle.nextToken()){
      if(handle.match(startSymbol)){
        if(count == 0 && startReplace != null){
          handle.remove();
          handle.insert(startReplace);
          handle.increment();
        }else{
          handle.increment();
        }

        count = count + 1;
      }else if(handle.match(endSymbol)){
        count = count - 1;

        if(count == 0 && endReplace != null){
          handle.remove();
          handle.insert(endReplace);
          handle.increment();
        }else{
          handle.increment();
        }
      }else{
        if(doProcess){
          process(handle);
        }else{
          handle.increment();
        }
      }

      if(count == 0){
        break;
      }
    }
  }

  private function consumeComments(handle : StringHandle) return{
    var comment = '';
    var position = handle.position;

    while(handle.nextToken()){
      if(handle.match('#')){
        comment += '#';
        handle.increment();
      }else{
        handle.increment();
        break;
      }
    }

    handle.position = position;
    handle.current = '#';

    if(comment.length > 2){
      handle.remove(comment);
      handle.insert('/** ');
      handle.increment();

      while(handle.nextToken()){
        if(handle.at(comment)){
          handle.remove(comment);
          handle.insert(' **/');
          handle.increment();
          break;
        }else if(handle.match('#')){
          position = handle.position;
          handle.prevToken();

          if(handle.match('\n') && onlyWhitespace(handle.content, position + 1, handle.position - 1)){
            handle.position = position;
            handle.remove('#');
            handle.insert('*');
          }else{
            handle.position = position;
          }

          handle.increment();
        }else{
          handle.increment();
        }
      }
    }else{
      if(handle.at('#elsif')){
        handle.remove('#elsif');
        handle.insert('#elseif');
      }else if(!handle.at('#if') && !handle.at('#else') && !handle.at('#end')){
        handle.remove(comment);
        handle.insert('//');
      }

      handle.next('\n');
      handle.increment();
    }

    return handle;
  }

  private function consumeStrings(handle : StringHandle) return{
    var multiline = false;

    if(handle.at('"""')){
      handle.remove('"""');
      handle.insert('\'');
      multiline = true;
    }else{
      handle.remove('"');
      handle.insert('\'');
    }

    handle.increment();

    while(handle.nextToken()){
      if(handle.match('#')){
        if(isNotEscaped(handle)){
          handle.remove();
          handle.insert('$$');
        }else{
          handle.position -= 1;
          handle.remove('\\');
        }

        handle.increment();
      }else if(handle.match('$$')){
        handle.insert('$$');
        handle.increment();
        handle.increment();
      }else if(handle.match('\'')){
        handle.insert('\\');
        handle.increment();
        handle.increment('\'');
      }else if(handle.match('"')){
        if(isNotEscaped(handle)){
          if(multiline){
            if(handle.at('"""')){
              handle.remove('"""');
              handle.insert('\'');
            }else{
              handle.insert('\\');
              handle.increment();
              handle.increment('"');
            }
          }else{
            handle.remove('"');
            handle.insert('\'');
          }

          break;
        }else{
          handle.position -= 1;
          handle.remove('\\');
          handle.increment();
        }
      }else{
        handle.increment();
      }
    }

    handle.increment();
  }

  private function consumeGenerics(handle : StringHandle) return{
    handle.remove();
    consumeBrackets(handle, '[', ']', '<', '>');
    var current = handle.current;
    var position = handle.position;
    handle.nextToken();

    if(handle.match('\n')){
      handle.insert(';');
    }else{
      handle.position = position;
      handle.current = current;
      handle.increment();
    }
  }

  private function isNotEscaped(handle : StringHandle) : Bool return{
    return (handle.content.charAt(handle.position -1) != '\\' ||
           (handle.content.charAt(handle.position -1) == '\\' && handle.content.charAt(handle.position -2) == '\\'));
  }

  private function consumeEndOfLine(handle : StringHandle, toInsert : String) : Bool return{
    var pos = handle.position;
    var insert = true;
    var isComment = handle.match('#');

    handle.prevToken();

    if((handle.matchOne(['=', ';', '+', '-', '*', '.', '/', ',' , '|', '&', '{', '(', '[', '^', '%', '~', '\n', '}', '?', ':', '<', '>']) ||
      handle.safeMatchOne(['is', 'isnt', 'and', 'or', 'not'])) && onlyWhitespace(handle.content, handle.position + 1, pos)){
      if(handle.match('-') || handle.match('+')){
        if(handle.content.charAt(handle.position - 1) != handle.current){
          insert = false;
        }
      }else{
        insert = false;
      }
    }

    handle.position = pos;

    if(!isComment){
      handle.increment('\n');
      handle.nextToken();

      if((handle.matchOne(['?', ':', '=', '+', '-', '*', '.', '/', ',' , '|', '&', ')', ']', '^', '%', '~', '>', '<']) ||
        handle.safeMatchOne(['is', 'isnt', 'and', 'or', 'not'])) && onlyWhitespace(handle.content, pos + 1, handle.position - 1)){
        insert = false;
      }

      handle.prev('\n');
    }

    if(insert && !handle.atStart()){
      handle.insert(toInsert);
      handle.increment();
    }

    if(isComment){
      consumeComments(handle);
    }else{
      handle.increment();
    }

    return insert && !handle.atStart();
  }

  private function consumeTables(handle : StringHandle) return{
    var pos = handle.position;
    var arrayAccess : Bool = true;
    handle.increment();

    while(safeNextToken(handle)){
      if(handle.match('[') && onlyWhitespace(handle.content, pos + 1, handle.position - 1)){
        var curr = opened;

        while(handle.nextToken()){
          if(opened == curr){
            if(handle.match('[')){
              consumeBrackets(handle, '[', ']', '', '');
            }else if(handle.match('=')){
              handle.remove();
              handle.insert('=>');
              handle.increment();
            }else if(handle.match('}')){
              break;
            }else{
              handle.increment();
            }
          }else{
            handle.increment();
          }
        }

        break;
      }else if(handle.match(':')){
        arrayAccess = false;
        break;
      }else if(handle.match('\n') || handle.match('"') || handle.match('#')){
        process(handle);
      }else{
        break;
      }
    }

    if(arrayAccess){
      handle.position = pos;
      consumeBrackets(handle, '{', '}', '[', ']');
    }
  }

  private function nextNoWhitespace(handle : StringHandle) return{
    while(handle.nextToken()){
      if(handle.match('\n')){
        handle.increment();
      }else if(handle.match('$')){
        consumeComments(handle);
      }else{
        break;
      }
    }
  }

  private function onlyWhitespace(content : String, from : Int, to : Int) return{
    ~/^\s*$/.match(content.substr(from, to - from));
  }
}
