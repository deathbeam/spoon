# raxe

[![Build Status](https://travis-ci.org/nondev/raxe.svg)](https://travis-ci.org/nondev/raxe) [![Join the chat at https://gitter.im/nondev/raxe](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/nondev/raxe?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

An awesome mix between Haxe and Ruby. Raxe is open source, cross-platform and compiles to Haxe without any performance penatly and runtime library.

# Installation

To install Raxe you can use haxelib

```
haxelib git raxe https://github.com/nondev/raxe.git
```

# Build the project

You'll need these libraries installed:

```
haxelib install mcli
haxelib install hscript
```

or you can just run

```
haxelib install build.hxml
```

to install all required dependencies.

Now, compile the project with

```
haxe build.hxml
```

A binary `run.n` will be available

# Command line tool

Base
--
If you installed the library with haxelib:

```
haxelib run raxe <commands>
```

On development :

```
neko run <commands> <cwd>
```

`<cwd>` stands for current working directory, so on Unix systems, you can simply pass `pwd` here.

Transpile
--

```
haxelib run raxe -s <raxe filename or directory> [-d <filename or directory>]
```

Arguments:
- `-s or --src` the source filename (raxe) or directory
- `-d or --dest` destination for the haxe file(s) generated. If omitted and src is a file, the dest will be the same filename in .hx. If omitted and src is a directory, the hx files will be generated in the same directory as raxe files.

Example : `haxelib run raxe -s examples/ -d dist/`

Will transpile all raxe files from examples to dist directory. Non raxe files will be just copy/paste to the new directory

Watch
--
If you want to automatically transpile modified raxe files, you can add argument `-w or --watch`. It will create an endless loop that will watch your files.

Example : `haxelib run raxe -s examples/ -d dist/ -w`

All files
--
If also want to copy other files other than raxe files, you can add the option `-a or --all`. So, if you have an image inside your raxe directories, it will be copied by the transpiler (by default, it's skipped). With this, you can have mixed project with both Haxe and Raxe source code.
