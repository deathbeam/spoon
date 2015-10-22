package raxe.cli;using Lambda;using StringTools;import sys.FileSystem;
import raxe.tools.Error;
import raxe.tools.FolderReader;
import raxe.compiler.Compiler;

class CompilerCommand{
  public var response : String;
  private var files = new Map<String, Int>();
  private var src : String;
  private var dest : String;
  private var all : Bool;
  private var verbose : Bool;

  /** 
  * @param src     Source file or directory
  * @param dest    Destination file or directory
  * @param all     If true, include also non-raxe files
  * @param verbose If true, display verbose info
   **/
  public function new(src: String, dest: String, all : Bool, verbose : Bool){
    this.src = src;
    this.dest = dest;
    this.all = all;
    this.verbose = verbose;
  }

  /** 
  * Compile a file or a whole directory
  * @return transpilation has been done or not
   **/
  public function compile() : Bool return{
    var src = this.src;
    var dest = this.dest;
    var dir = src;

    // Compile one file
    if(!FileSystem.isDirectory(this.src)){
      var oldFileSize : Int = this.files.get(this.src);
      var currentSize : Int = FileSystem.stat(this.src).size;

      if(oldFileSize != currentSize){
        src = getSourceFile(src);
        printVerbose(src, dest);
        var result = compileFile(dest, src);

        if(dest == null || dest == ""){
            this.response = result;
        }else{
            FolderReader.createFile(dest, result);
        }

        this.files.set(this.src, currentSize);
        return true;
      }

      return false;
    // Compile a whole folder
    }else{
      var files = FolderReader.getFiles(src);
      var hasCompile : Bool = false;

      // To have the same pattern between src and dest (avoid src/ and dist instead of dist/)
      if(src.endsWith("/")){
        src = src.substr(0, src.length - 1);
      }

      if(dest == null || dest == ""){
        dest = src;
      }else if(dest.endsWith("/")){
        dest = dest.substr(0, dest.length - 1);
      }

      var currentFiles = new Map<String, Int>();

      for(file in files.iterator()){
        var oldFileSize : Int = this.files.get(file);
        var currentSize : Int = FileSystem.stat(file).size;

        if(oldFileSize != currentSize && (all || isRaxeFile(file))){
          var newPath = this.getDestinationFile(file, src, dest);

          // If it's a raxe file, we compile it
          if(isRaxeFile(file)){
            file = getSourceFile(file);
            printVerbose(file, newPath);
            var result = compileFile(dir, file);
            FolderReader.createFile(newPath, result);
            this.files.set(file, currentSize);

          // If it's not a raxe file, we just copy/past it to the new folder
          }else{
              FolderReader.copyFileSystem(file, newPath);
          }

          this.files.set(file, currentSize);
          hasCompile = true;
        }

        currentFiles.set(file, currentSize);
      }

      for(key in this.files.keys()){
        if(currentFiles.get(key) == null){
          this.files.remove(key);
          FileSystem.deleteFile(this.getDestinationFile(key, src, dest));
        }
      }

      return hasCompile;
    }

    return false;
  }

  /** 
  * Print verbose info to console
  * @param src  Source file
  * @param dest Destination file
   **/
  private function printVerbose(src : String, dest : String) return{
    if(verbose){
      Sys.println("Compiling " + src + "\n" + "       to " + dest);
    }
  }

  /** 
  * Compile one file
  * @param file Compile a file and returns its content
  * @return content
   **/
  private function compileFile(dir : String, file: String): String return{
    var compiler = new Compiler();
    dir = dir != null ? FileSystem.fullPath(dir) : Sys.getCwd();

    return compiler.compile(dir, file);
  }

  /** 
  * Checks if the given file is a raxe file
  * @param filename Name of file to check for
  * @return if it is raxe file or not
   **/
  private function isRaxeFile(filename: String): Bool return{
    return filename.endsWith(".rx");
  }

  /** 
  * Get the path to the source file
  * @param file Path to the file
  * @return source file path
   **/
  private function getSourceFile(file : String) : String return{
    FileSystem.fullPath(file);
  }

  /** 
  * Get the path to the destination file
  * @param file Path to the file
  * @param src  Source directory
  * @param dest Destination directory
  * @return destination file path
   **/
  private function getDestinationFile(file: String, src: String, dest: String) : String return{
    var parts : Array<String> = file.split("/");
    var fileName : String = parts.pop();

    var newPath = parts.join("/") + "/" + fileName.replace(".rx", ".hx");

    if(dest != null){
      newPath = newPath.replace(src, dest);
    }

    return newPath;
  }
}
