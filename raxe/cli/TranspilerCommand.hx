package raxe.cli;

import sys.FileSystem;
import raxe.tools.Error;
import raxe.tools.FolderReader;
using StringTools;

class TranspilerCommand
{
    public static inline var ERROR_TYPE = "transpile_error";

    /**
     * Transpile a file or a whole directory
     *
     * @param String src   Source file or directory
     * @param String ?dest Destination file or directory (optional)
     *
     * @return String A file if no destination provided
     */
    public static function transpile(src: String, ?dest: String) : String
    {
        if (!FileSystem.exists(src)) {
            Error.create(ERROR_TYPE, "Source not found");
        }

        // Transpile one file
        if (!FileSystem.isDirectory(src)) {
            var result = transpileFile(src);

            if (dest == null) {
                return result;
            }

            FolderReader.createFile(dest, result);

        // Transpile a whole folder
        } else {
            var files = FolderReader.getFiles(src);

            // To have the same pattern between src and dest (avoid src/ and dist instead of dist/)
            if (src.endsWith("/")) {
                src = src.substr(0, src.length - 1);
            }

            if (dest.endsWith("/")) {
                dest = dest.substr(0, dest.length - 1);
            }

            Sys.println(files.length + " files to transpile from " + src);
            for (file in files.iterator()) {
                var parts : Array<String> = file.split('/');
                var fileName : String = parts.pop();

                var newPath = parts.join("/") + "/" + fileName.replace(".rx", ".hx");

                if (dest != null) {
                    newPath = newPath.replace(src, dest);
                }
                // If it's a raxe file, we transpile it
                if (isRaxeFile(file)) {
                    var result = transpileFile(file);
                    FolderReader.createFile(newPath, result);

                // If it's not a raxe file, we just copy/past it to the new folder
                } else {
                    FolderReader.copyFileSystem(file, newPath);
                }
            }
        }

        return "";
    }

    /**
     * Transpile one file
     *
     * @param String file Transpile a file and returns its content
     *
     * @return String content
     */
    public static function transpileFile(file: String): String
    {
        var group = new TranspilerGroup();

        group
            .push(new CoreTranspiler())
            .push(new AccessTranspiler())
            .push(new SemicolonTranspiler())
        ;

        return group.transpile(Sys.getCwd(), file);
    }

    /**
     * Checks if the given file is a raxefile
     */
    public static function isRaxeFile(filename: String): Bool
    {
        return filename.endsWith(".rx");
    }
}
