package my.app.native_libs

class FormatConverter {
    companion object {
        // Used to load the 'native_libs' library on application startup.
        init {
            System.loadLibrary("native_libs")
        }
        external fun list2webp(listPath: String, webpPath: String): Int
    }
}