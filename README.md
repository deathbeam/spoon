```
.d8888. d8888b.  .d88b.   .d88b.  d8b   db
88'  YP 88  `8D .8P  Y8. .8P  Y8. 888o  88
`8bo.   88oodD' 88    88 88    88 88V8o 88
  `Y8b. 88~~~   88    88 88    88 88 V8o88
db   8D 88      `8b  d8' `8b  d8' 88  V888
`8888Y' 88       `Y88P'   `Y88P'  VP   V8P
```

[![Build Status](https://travis-ci.org/nondev/spoon.svg)](https://travis-ci.org/nondev/spoon) [![Join the chat at https://gitter.im/nondev/spoon](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/nondev/spoon?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Spoon is awesome new programming language, what combines the best things from [https://ruby-lang.org](Ruby) and [https://python.org](Python). Spoon is open source, cross-platform and runs on top of [https://haxe.org](Haxe).

Projects written in Spoon can run natively on any platform that Haxe supports, so

  * Any platform on what you can run C++, so almost everywhere
  * Android/iOS/Windows Phone
  * Windows/Linux/Mac
  * Browser (NodeJS, HTML5, PHP, AS3)

**Spoon is still in heavy development and not usable yet, so feel free to help me and contribute**

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
