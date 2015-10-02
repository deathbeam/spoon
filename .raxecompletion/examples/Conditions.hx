package examples;using Lambda;using StringTools;class Conditions{

static dynamic public function main(){
  var myvar : String = null;
  var myarray =new  Array<String>();

  if(myvar != null && myvar.charAt(10) == "p"){
    for(i in myarray.iterator()){
      trace("Wouhou");
    }
  }else if(myvar != null && myvar.charAt(20) == "c"){
    trace("no");
  }else{
    trace("coco");
  }

  if(myvar != null &&
      myvar.charAt(0) == "x" &&
      myvar.charAt(2) == "x"){
    trace("ok");
  }
};
}