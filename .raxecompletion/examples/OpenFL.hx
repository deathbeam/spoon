package examples;using Lambda;using StringTools;;// Load OpenFL libraries
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.Assets;

// Extend self by OpenFL Sprite
class OpenFL extends Sprite{

public var logo : Sprite;
public var movingDown : Bool;
public var movingLeft : Bool;
public var movingRight : Bool;
public var movingUp : Bool;

public function new(){
  super();

  logo =new  Sprite();
  logo.addChild(new Bitmap(Assets.getBitmapData("assets/openfl.png")));
  logo.x = 100;
  logo.y = 100;
  logo.buttonMode = true;
  addChild(logo);

  stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
  stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
  stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
};

/** 
Event handlers
 **/

dynamic public function onKeyDown(event){
  if(event.keyCode == Keyboard.DOWN){
    movingDown = true;
  }else if(event.keyCode == Keyboard.LEFT){
    movingLeft = true;
  }else if(event.keyCode == Keyboard.RIGHT){
    movingRight = true;
  }else if(event.keyCode == Keyboard.UP){
    movingUp = true;
  }
};

dynamic public function onKeyUp(event){
  if(event.keyCode == Keyboard.DOWN){
    movingDown = false;
  }else if(event.keyCode == Keyboard.LEFT){
    movingLeft = false;
  }else if(event.keyCode == Keyboard.RIGHT){
    movingRight = false;
  }else if(event.keyCode == Keyboard.UP){
    movingUp = false;
  }
};

dynamic public function onEnterFrame(event){
  if(movingDown){
    logo.y += 5;
  }

  if(movingLeft){
    logo.x -= 5;
  }

  if(movingRight){
    logo.x += 5;
  }

  if(movingUp){
    logo.y -= 5;
  }
};
}