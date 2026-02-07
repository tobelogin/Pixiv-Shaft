package my.app.native_libs

class FormatConverter {
    companion object {
        // Used to load the 'native_libs' library on application startup.
        init {
            System.loadLibrary("native_libs")
        }

        fun list2webp(listPath: String, webpPath: String): Int {
            return nativeList2Webp(listPath.toByteArray(Charsets.UTF_8), webpPath.toByteArray(Charsets.UTF_8))
        }
        external fun nativeList2Webp(listPath: ByteArray, webpPath: ByteArray): Int
    }
}