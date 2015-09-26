package raxe.cli;

import mcli.CommandLine;
import raxe.tools.Error;
import sys.FileSystem;

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

    public static inline var ERROR_TYPE = "transpile_error";

    /**
        Source directory or file
        @alias s
     **/
    public var src : String;

    /**
        Destination directory or file
        @alias d
     **/
    public var dest : String;

    /**
        Execute the command when source file(s) are changed
        @alias w
     **/
    public var watch : Bool;

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
        if (this.src != null) {
            if (!FileSystem.exists(src)) {
                Error.create(ERROR_TYPE, "Source not found");
            }

            var transpiler = new TranspilerCommand(this.src, this.dest);
            while (true) {
                try {
                    if (transpiler.transpile()) {
                        if (transpiler.response != null && transpiler.response != "") {
                            Sys.println(transpiler.response);
                        } else {
                            Sys.println("Transpilation done.");
                        }
                    }
                } catch (err : String) {
                    Sys.println(err);
                }

                if (!this.watch) {
                    break;
                }
            }
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
