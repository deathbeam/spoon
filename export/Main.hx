package export;// testing something right
import openfl.display.Sprite
// testing something right
import openfl.events.Event // testing something right
import openfl.Lib

// require "openfl/Lib"

/* 
Some random things right?
I do not found good syntax how to define what is
this. Any suggestions?
 */
 class Main <String> 
  extends Sprite
  implements Dynamic
  
{// Module variables
static var appname = "My Application"
static var instance = new Main() // New instance of self

/* 
Instance variables
 */
var cacheTime : Float
var speed : Float
var sprite : Sprite

var struct = {
  a: "hello",
  b: "world",
  callback: function(test){
    trace("hello world")
  }
}

var array = [
  "hello", "world"
]

// Just multiline string
// Yes I know Haxe supports them already
// but this is solely for syntax highlighting purposes
var test = "
  Hello bro.
  This is new line bro.
  Okay bro.
"

static function instance(){
  return instance // Return instance of Main
}

// Create a new instance of class Main
// It is just entry point for OpenFL
function new(){
  super()

  /* 
  Print something
   */
  trace("This is " + appname)

  // Create our super sprite
  sprite = new Sprite()
  sprite.graphics.beginFill(0x24AFC4)
  sprite.graphics.drawRect(0, 0, 100, 100)
  sprite.y = 50
  addChild(sprite)

  // Initialize rest of things
  speed = 0.3
  cacheTime = Lib.getTimer()

  while (true){
    trace(hello)
    break
  }

  // Event listener magic, hell yeah
  addEventListener(Event.ENTER_FRAME, function(event){
    var currentTime = Lib.getTimer ()
    update (currentTime - cacheTime)
    cacheTime = currentTime
  })
}

// Just main loop. I love them.
function update(deltaTime){
  if (sprite.x + sprite.width >= stage.stageWidth || sprite.x <= 0){  
    speed *= -1
  }else if (sprite.x == 5){
    testThis()
    break
  }else{
    testThat()
  }

  sprite.x += speed * deltaTime
}}