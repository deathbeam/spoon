package examples;using Lambda;using StringTools;class Lambdas{

static dynamic public function main(){
  var numbers = [1, 3, 5, 6, 7, 8];

  trace(numbers.count()) ;// 6
  trace(numbers.has(4)) ;// false

  // test if all numbers are greater/smaller than 20
  trace(numbers.foreach(function(v){
    return v < 20;
  })) ;// true

  trace(numbers.foreach(function(v){
    return v > 20;
  })) ;// false

  // sum all the numbers
  var sum = function(num, total){
    return total += num;
  };

  trace(numbers.fold(sum, 0)) ;// 30
};

}