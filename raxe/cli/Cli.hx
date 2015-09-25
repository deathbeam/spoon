package raxe.cli;

import mcli.CommandLine;

/**
    raxe-lang command line tool
    Transpile your raxe sources into haxe
 **/
class Cli extends CommandLine {
    /**
        Source directory or file
        @alias s
     **/
    public var src : String;

    /**
        Destination directory or file (default /dist)
        @alias d
     **/
    public var dest : String;

    /**
        Show this message
        @alias h
     **/
    public function help() {
        Sys.println(this.showUsage());
        Sys.exit(0);
    }

    /**
       Transpile command
       @alias t
     **/
    public function transpile() {
        try {
            if (this.src != "") {
                var response = TranspilerCommand.transpile(this.src, this.dest);

                if (response != "") {
                    Sys.println(response);
                    Sys.exit(0);
                }

                Sys.println("Transpilation done.");
            }
        } catch (err : String) {
            Sys.println(err);
        }

        Sys.exit(0);
    }

    public function runDefault() {
        try {
            this.help();
        } catch (err : String) {
            Sys.println(err);
            Sys.exit(0);
        }
    }
}
