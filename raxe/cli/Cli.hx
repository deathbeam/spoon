package raxe.cli;

import mcli.CommandLine;

/**
    -
    8b,dPPYba,  ,adPPYYba,  8b,     ,d8  ,adPPYba,  
    88P'   "Y8  ""     `Y8   `Y8, ,8P'  a8P_____88  
    88          ,adPPPPP88     )888(    8PP"""""""  
    88          88,    ,88   ,d8" "8b,  "8b,   ,aa  
    88          `"8bbdP"Y8  8P'     `Y8  `"Ybbd8"'  

    Raxe 0.0.1 - https://raxe-lang.org
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
