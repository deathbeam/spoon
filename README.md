```
.d8888. d8888b.  .d88b.   .d88b.  d8b   db
88'  YP 88  `8D .8P  Y8. .8P  Y8. 888o  88
`8bo.   88oodD' 88    88 88    88 88V8o 88
  `Y8b. 88~~~   88    88 88    88 88 V8o88
db   8D 88      `8b  d8' `8b  d8' 88  V888
`8888Y' 88       `Y88P'   `Y88P'  VP   V8P
```


[![Build Status](https://travis-ci.org/nondev/spoon.svg)](https://travis-ci.org/nondev/spoon) [![Join the chat at https://gitter.im/nondev/raxe](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/nondev/spoon?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Spoon is awesome new programming language, what combines the best things from CoffeeScript, Python and Haxe. Spoon is open source, cross-platform and compiles to Haxe without any performance penalty and runtime library.

**Spoon is still in heavy development and not usable yet, so feel free to help me and contribute :smile:**

# Installation

To install Spoon you can use haxelib

```
haxelib git spoon https://github.com/nondev/spoon.git
```

# Build from source

First, to install all dependencies, run

```
haxelib install build.hxml
```

Now, to build `neko` executable `run.n`, simply run this

```
haxe build.hxml
```

# Example

Hopefully, when Spoon will be finished, it's syntax will awesome like this:

```coffee
from Foo import Bar as Chocolate # Python-like imports and module system

# Interfaces with default implementation
interface Printer
  function print(message)
    trace message # Optional parenthesis

class Hello
  function hello
    return "Hello"

class World extends Hello
  function world
    return "World"

class Messenger extends World
  implements Printer

  function this.run
    self = Messenger.new! # Ruby-like method of creating new objects
    print "#{self.hello!} #{self.world!}" # Ruby-like string interpolation

# Generic types and static typing
class MyValue[T]
  value as T

  function new(value as T)
    this.value = value

trace MyValue[String].new("HI!")
trace MyValue[Int].new(5)
Messenger.run! # Exclamation mark used for 0-arg argument calls
```
