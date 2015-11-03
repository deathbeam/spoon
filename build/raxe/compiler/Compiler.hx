package raxe.compiler;using Lambda;using StringTools;import raxe.tools.StringHandle;
#if !js
  import sys.io.File;
#end

/** 
* The most important Raxe class, which compiles Raxe source to Haxe source
 **/
@:tink class Compiler{
  private var name : String = '';
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
    '::', 'class', 'enum', 'abstract', 'interface',

    // Modifiers
    'public', 'private',

    // Special keywords
    'import', 'def', 'new', 'end', 'do', 'typedef', 'try', 'catch', 'empty',

    // Brackets
    '{', '}', '(', ')', '[', ']',

    // Operators (- is also used for comments, < is also used for inheritance)
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

      name = currentPackage
        .substr(currentPackage.lastIndexOf('/') + 1)
        .replace('.rx', '');

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
    if(handle.is('$$') && handle.at('$$[')){
      handle.remove();
      handle.insert('@');
      handle.increment();
      consumeBrackets(handle, '[', ']', true);
      safeNextToken(handle);

      if(handle.is('\n')){
        handle.increment();
      }
    }else if(handle.is('@@')){
      if(handle.safeis('@@')){
        handle.remove();
        handle.insert(name);
      }else{
        handle.remove();
        handle.insert(name + '.');
      }

      handle.increment();
    }else if(handle.is('/')){
      handle.remove();
      handle.insert('~/');

      while(handle.nextToken()){
        if(handle.is('/') && isNotEscaped(handle)){
          handle.increment();
          break;
        }

        handle.increment();
      }
    }else if(handle.is('@')){
      if(handle.safeis('@')){
        handle.remove();
        handle.insert('this');
      }else{
        handle.remove();
        handle.insert('this.');
      }

      handle.increment();
    // Step over things in strings (" ") and process multiline strings
    }else if(handle.is('"')){
      consumeStrings(handle);
    // Correct access
    }else if(handle.safeis('public') || handle.safeis('private')){
      hasVisibility = true;
      handle.increment();
    // Change require to classic imports
    }else if(handle.safeis('import')){
      handle.next('\n');
      handle.insert(';');
      handle.increment();
    // Empty operator (null)
    }else if(handle.safeis('empty')){
      handle.remove();
      handle.insert('null');
      handle.increment();
    // Structures and arrays
    }else if(handle.is('{') || handle.is('[')){
      opened = opened + 1;
      handle.increment();
    }else if(handle.is('}') || handle.is(']')){
      opened = opened - 1;

      if(opened == -1){
        currentType = '';
      }

      handle.increment();
    // Change end to classic bracket end
    }else if(handle.safeis('end')){
      handle.remove();
      handle.insert('}');
      handle.increment();
      opened = opened - 1;

      if(currentOpened == opened){
        currentOpened = -1;
        currentExpression = '';
      }
    // Insert begin bracket after switch
    }else if(handle.safeis('switch')){
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
    }else if(handle.safeis('when')){
      handle.remove();
      handle.insert('case');
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert(':');
      handle.increment();
    // Insert begin bracket after try
    }else if(handle.safeis('try')){
      handle.increment();
      handle.insert('{');
      handle.increment();
      opened = opened + 1;
    // Insert brackets around catch
    }else if(handle.safeis('catch')){
      handle.insert('}');
      handle.increment();
      handle.increment('catch');
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
    // Insert begin bracket after if and while
    }else if(handle.safeis('if')){
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
      opened = opened + 1;
    // Change elseif to else if and insert begin and end brackets around it
    }else if(handle.safeis('elsif')){
      handle.remove();
      handle.insert('}else if');
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      handle.increment();
    // Insert begin brackets after loops declaration
    }else if(handle.safeis('while') || handle.safeis('for')){
      handle.increment();
      handle.nextToken();
      consumeBrackets(handle, '(', ')');
      handle.next('\n');
      handle.insert('{');
      opened = opened + 1;
      handle.increment();
    // Inser begin and end brackets around else but do not try to
    // process curlys because there will not be any
    }else if(handle.safeis('else')){
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
    }else if(handle.safeis('def')){
      handle.remove('def');

      var position = handle.position;

      if(opened == 0 && !script){
        if(!hasVisibility){
          handle.insert('public ');
          handle.increment();
        }

        position = handle.position;
        safeNextToken(handle);

        if(handle.is('@new')){
          handle.remove();
          handle.insert('static var __new = (function(){_new(); return true;})(); static  _new');
          handle.increment();
          position = handle.position - 5;
        }else if(handle.is('@')){
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

      if(handle.safeis('new')){
        implicit = false;
        handle.increment();
        handle.nextToken();
      }

      if(handle.is('(')){
        handle.position = position;
        handle.insert('function');
        consumeBrackets(handle, '(', ')');

        if(currentType != 'interface'){
          while(safeNextToken(handle)){
            if(handle.is('do')){
              handle.remove();

              if(implicit){
                handle.insert('return');
              }

              break;
            }else if(handle.isOne(['\n', '#'])){
              if(implicit){
                handle.insert(' return{');
              }else{
                handle.insert('{');
              }
              handle.increment();
              opened = opened + 1;
              break;
            }else{
              handle.increment();
            }
          }
        }else{
          handle.insert(';');
          handle.increment();
        }
      }else{
        handle.position = position;
        handle.insert('var');
        handle.increment();
      }
    // Closures and blocks
    }else if(handle.safeis('do')){
      handle.remove('do');
      handle.insert('{');
      opened = opened + 1;
      handle.increment();
    // [abstract] class/interface/enum
    }else if (handle.safeis('class') || handle.safeis('interface') || handle.safeis('enum')){
      currentType = handle.current;
      handle.insert('@:tink ');
      handle.increment();
      handle.increment(currentType);

      while(handle.nextToken()){
        if(handle.is('@')){
          handle.remove();
          handle.insert(name);
        }else if(handle.is('<')){
          handle.remove();
          handle.insert('extends');
        }else if(handle.is('::')){
          handle.remove();
          handle.insert('implements');
        }else if(handle.is('\n')){
          handle.insert('{');
          break;
        }

        handle.increment();
      }
    // Process comments and newlines. Also, insert semicolons when needed
    }else if(handle.is('\n') || handle.is('#')){
      consumeEndOfLine(handle, ';');
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
        safeCheck(handle, 'private') && safeCheck(handle, 'public') && safeCheck(handle, 'empty') && safeCheck(handle, 'switch') &&
        safeCheck(handle, 'when')){
      return true;
    }else{
      handle.increment();
      return safeNextToken(handle);
    }
  }

  private function safeCheck(handle : StringHandle, content : String) : Bool return{
    if(handle.is(content)){
      return handle.safeis(content);
    }

    return true;
  }

  private function consumeCondition(handle : StringHandle, condition : String) return{
    handle.increment();
    handle.insert('(');
    handle.increment();

    var curLevel = opened;

    while(handle.nextToken()){
      if(curLevel == opened && (handle.is('\n') || handle.is('#'))){
        if(consumeEndOfLine(handle, '){')){
          break;
        }
      }else{
        process(handle);
      }
    }
  }

  private function consumeBrackets(handle : StringHandle, startSymbol : String, endSymbol : String, remove : Bool = false) return{
    var count = 0;
    var startPosition = handle.position;

    while(handle.nextToken()){
      if(handle.is(startSymbol)){
        if(count == 0 && remove){
          handle.remove();
        }else{
          handle.increment();
        }

        count = count + 1;
      }else if(handle.is(endSymbol)){
        count = count - 1;

        if(count == 0 && remove){
          handle.remove();
        }else{
          handle.increment();
        }
      }else{
        process(handle);
      }

      if(count == 0){
        break;
      }
    }
  }

  private function consumeComments(handle : StringHandle) return{
    var comment = '';
    var position = handle.position;

    while(handle.nextTokenLine()){
      if(handle.is('#')){
        comment += '#';
        handle.increment();
      }else{
        handle.increment();
        break;
      }
    }

    handle.position = position;
    handle.current = '#';

    if(comment.length > 1){
      handle.remove(comment);
      handle.insert('/** ');
      handle.increment();

      while(handle.nextToken()){
        if(handle.at(comment)){
          handle.remove(comment);
          handle.insert(' **/');
          handle.increment();
          break;
        }else if(handle.is('#')){
          position = handle.position;
          handle.prevToken();

          if(handle.is('\n') && onlyWhitespace(handle.content, position + 1, handle.position - 1)){
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
      if(handle.is('#')){
        if(isNotEscaped(handle)){
          handle.remove();
          handle.insert('$$');
        }else{
          handle.position -= 1;
          handle.remove('\\');
        }

        handle.increment();
      }else if(handle.is('$$')){
        handle.insert('$$');
        handle.increment();
        handle.increment();
      }else if(handle.is('\'')){
        handle.insert('\\');
        handle.increment();
        handle.increment('\'');
      }else if(handle.is('"')){
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

  private function isNotEscaped(handle : StringHandle) : Bool return{
    return (handle.content.charAt(handle.position -1) != '\\' ||
           (handle.content.charAt(handle.position -1) == '\\' && handle.content.charAt(handle.position -2) == '\\'));
  }

  private function consumeEndOfLine(handle : StringHandle, toInsert : String) : Bool return{
    var pos = handle.position;
    var insert = true;
    var isComment = handle.is('#');

    handle.prevTokenLine();

    if(handle.isOne(['=', ';', '+', '-', '*', '.', '/', ',' , '|', '&', '{', '(', '[', '^', '%', '~', '\n', '}', '?', ':']) && onlyWhitespace(handle.content, handle.position + 1, pos)){
      if(handle.is('-') || handle.is('+')){
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

      if(handle.isOne(['?', ':', '=', '+', '-', '*', '.', '/', ',' , '|', '&', ')', ']', '^', '%', '~']) && onlyWhitespace(handle.content, pos + 1, handle.position - 1)){
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

  private function onlyWhitespace(content : String, from : Int, to : Int) return{
    var sub = content.substr(from, to - from);
    var regex = new EReg('^\\s*$$', '');
    return regex.match(sub);
  }
}
