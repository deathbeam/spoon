// Require some other modules
import openfl.display.Sprite;
import openfl.display.Sprite;
import openfl.display.Sprite;

// Set type of this module to class and extend it by OpenFL sprite
module class extends Sprite
  
// Module variables
static var appname = "My Application"
static var instance = new Main() // Test

static function instance() {
  return instance // Return instance of Main
}

// Instance variables
var cacheTime : Float
var speed : Float
var sprite : Sprite

// Create a new instance of class Main
// It is just entry point for OpenFL
function new() {
  super()

  puts("This is " + appname)

  // Create our super sprite
  sprite = new Sprite()
  sprite.graphics.beginFill(0x24AFC4)
  sprite.graphics.drawRect(0, 0, 100, 100)
  sprite.y = 50
  addChild(sprite)

  // Initialize rest of things
  speed = 0.3
  cacheTime = Lib.getTimer()

  // Event listener magic, hell yeah
  addEventListener(Event.ENTER_FRAME, function(event) {
    var currentTime = Lib.getTimer ()
    update (currentTime - cacheTime)
    cacheTime = currentTime
  })
}

// Just main loop. I love them.
function update(deltaTime) {
  if (sprite.x + sprite.width >= stage.stageWidth || sprite.x <= 0)  
    speed *= -1
  }

  sprite.x += speed * deltaTime
}}