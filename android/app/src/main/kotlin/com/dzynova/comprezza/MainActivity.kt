package com.dzynova.comprezza

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Hosts Flutter and exposes scoped-storage-safe gallery/Downloads export. */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "comprezza/device_export"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "saveToMediaStore" -> saveImage(call, result)
                        "saveToDownloads" -> saveDownload(call, result)
                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    result.error("EXPORT_FAILED", exception.message, null)
                }
            }
    }

    private fun saveImage(call: MethodCall, result: MethodChannel.Result) {
        val source = sandboxedSource(call)
        val extension = source.extension.lowercase()
        val mimeType = when (extension) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            "heic" -> "image/heic"
            "avif" -> "image/avif"
            else -> error("Unsupported image format.")
        }
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, safeDisplayName(source.name, extension))
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Comprezza")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = applicationContext.contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values,
        ) ?: error("MediaStore did not create an image entry.")
        writePending(uri, source, values)
        result.success(null)
    }

    private fun saveDownload(call: MethodCall, result: MethodChannel.Result) {
        val source = sandboxedSource(call)
        val extension = source.extension.lowercase()
        val mimeType = if (extension == "zip") {
            "application/zip"
        } else {
            "application/octet-stream"
        }
        // Note: unlike MediaStore.Images, MediaStore.Downloads has no nested
        // "Media" class - its columns and the EXTERNAL_CONTENT_URI live directly
        // on the Downloads class (API 29+).
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, safeDisplayName(source.name, extension))
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Comprezza")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = applicationContext.contentResolver.insert(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI, values,
        ) ?: error("MediaStore did not create a download entry.")
        writePending(uri, source, values)
        result.success(null)
    }

    private fun sandboxedSource(call: MethodCall): File {
        val sourcePath = call.argument<String>("path")
            ?: throw IllegalArgumentException("The source path is missing.")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw UnsupportedOperationException("MediaStore export requires Android 10 or newer.")
        }
        val source = File(sourcePath).canonicalFile
        require(source.isFile) { "The file does not exist." }
        // The Flutter side may only export generated files from the app
        // sandbox. Canonicalization also blocks symlink escapes.
        val allowedRoots = listOf(
            File(applicationContext.cacheDir, "cache").canonicalFile,
            File(applicationContext.filesDir, "compression").canonicalFile,
            File(applicationContext.filesDir, "exports").canonicalFile,
        )
        require(allowedRoots.any { root -> source.isDescendantOf(root) }) {
            "The export source is outside app-owned storage."
        }
        return source
    }

    private fun writePending(uri: Uri, source: File, values: ContentValues) {
        val resolver = applicationContext.contentResolver
        try {
            resolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: error("Unable to open the device destination.")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            val updatedRows = resolver.update(uri, values, null, null)
            check(updatedRows == 1) { "MediaStore did not finalize the entry." }
        } catch (exception: Exception) {
            resolver.delete(uri, null, null)
            throw exception
        }
    }

    private fun File.isDescendantOf(root: File): Boolean {
        val rootPath = root.canonicalPath.trimEnd(File.separatorChar) + File.separator
        return canonicalPath.startsWith(rootPath)
    }

    private fun safeDisplayName(name: String, extension: String): String {
        val sanitized = name
            .replace(Regex("[^A-Za-z0-9._-]"), "_")
            .trim('_', '.')
        return if (sanitized.isBlank()) {
            "photo_compressed_${System.currentTimeMillis()}.$extension"
        } else {
            sanitized
        }
    }
}
