package raxe.cli;using Lambda;using StringTools;// vim: set ft=rb:

import sys.FileSystem;
import raxe.tools.Error;
import raxe.tools.FolderReader;
import raxe.transpiler.Transpiler;

class TranspilerCommand{
  public var response : String;
  private var files =new  Map<String, Int>();
  private var src : String;
  private var dest: String;

  /** 
  @param String src   Source file or directory
  @param String ?dest Destination file or directory (optional)
   **/
  public function new(src: String, ?dest: String){
    this.src = src;
    this.dest = dest;
  }

  /** 
  Transpile a file or a whole directory

  @param raxeOnly Bool Must only copy to the dest directory, raxe files
  @return Bool transpilation has been done or not
   **/
  public function transpile(all: Bool) : Bool return{
    var src = this.src;
    var dest = this.dest;
    var dir = src;

    // Transpile one file
    if(!FileSystem.isDirectory(this.src)){
      var oldFileSize : Int = this.files.get(this.src);
      var currentSize : Int = FileSystem.stat(this.src).size;

      if(oldFileSize == null || oldFileSize != currentSize){
        var result = transpileFile(dest, src);

        if(dest == null){
            this.response = result;
        }else{
            FolderReader.createFile(dest, result);
        }

        this.files.set(this.src, currentSize);
        return true;
      }

      return false;
    // Transpile a whole folder
    }else{
      var files = FolderReader.getFiles(src);
      var hasTranspile : Bool = false;

      // To have the same pattern between src and dest (avoid src/ and dist instead of dist/)
      if(src.endsWith("/")){
        src = src.substr(0, src.length - 1);
      }

      if(dest == null){
        dest = src;
      }else if(dest.endsWith("/")){
        dest = dest.substr(0, dest.length - 1);
      }

      var currentFiles =new  Map<String, Int>();

      for(file in files.iterator()){
        var oldFileSize : Int = this.files.get(file);
        var currentSize : Int = FileSystem.stat(file).size;

        if(oldFileSize != currentSize && (all || isRaxeFile(file))){
          var newPath = this.getDestinationFile(file, src, dest);

          // If it's a raxe file, we transpile it
          if(isRaxeFile(file)){
            var result = transpileFile(dir, file);
            FolderReader.createFile(newPath, result);
            this.files.set(file, currentSize);

          // If it's not a raxe file, we just copy/past it to the new folder
          }else{
              FolderReader.copyFileSystem(file, newPath);
          }

          this.files.set(file, currentSize);
          hasTranspile = true;
        }

        currentFiles.set(file, currentSize);
      }

      for(key in this.files.keys()){
        if(currentFiles.get(key) == null){
          this.files.remove(key);
          FileSystem.deleteFile(this.getDestinationFile(key, src, dest));
        }
      }

      return hasTranspile;
    }

    return false;
  }

  /** 
  Transpile one file

  @param String file Transpile a file and returns its content
  @return String content
   **/
  public function transpileFile(dir : String, file: String): String return{
    var transpiler =new  Transpiler();
    dir = dir != null ? FileSystem.fullPath(dir) : Sys.getCwd();
    file = FileSystem.fullPath(file);

    Sys.println("Compiling " + file);
    return transpiler.transpile(dir, file);
  }

  /** 
  Checks if the given file is a raxefile
   **/
  public function isRaxeFile(filename: String): Bool return{
    return filename.endsWith(".rx");
  }

  /** 
  Get the path the destination file

  @param String file Path to the file
  @param String src  Source directory
  @param String dest Destination directory
  @return String destination file path
   **/
  public function getDestinationFile(file: String, src: String, dest: String) : String return{
    var parts : Array<String> = file.split("/");
    var fileName : String = parts.pop();

    var newPath = parts.join("/") + "/" + fileName.replace(".rx", ".hx");

    if(dest != null){
      newPath = newPath.replace(src, dest);
    }

    return newPath;
  }
}
