package com.appexbusiness.apna_ledger

import android.app.DownloadManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth (App Lock / biometrics) shows the system BiometricPrompt, which
// needs a FragmentActivity. With a plain FlutterActivity every authenticate()
// call fails with "no_fragment_activity".
class MainActivity : FlutterFragmentActivity() {

    private val folder = "ApnaLedger"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "apna_ledger/downloads",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "save" -> result.success(
                        save(
                            call.argument<String>("name")!!,
                            call.argument<String>("mime")!!,
                            call.argument<ByteArray>("bytes")!!,
                        ),
                    )
                    "delete" -> {
                        delete(call.argument<String>("name")!!)
                        result.success(null)
                    }
                    "folderLabel" -> result.success(folderLabel())
                    "openFolder" -> result.success(openFolder())
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("downloads", e.message, null)
            }
        }
    }

    /** Human-readable location shown in "My downloads". */
    private fun folderLabel(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "Internal storage/Download/$folder"
        } else {
            legacyDir().absolutePath
        }

    private fun legacyDir(): File =
        File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), folder).apply { mkdirs() }

    /**
     * Writes a public copy to Download/ApnaLedger (MediaStore on Android 10+,
     * no storage permission needed). Older versions use the app's external
     * Downloads folder. Returns the display path.
     */
    private fun save(name: String, mime: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            delete(name) // replace an older copy with the same name
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/$folder",
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create $name")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "${folderLabel()}/$name"
        }
        val file = File(legacyDir(), name)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    private fun delete(name: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            contentResolver.delete(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                "${MediaStore.Downloads.DISPLAY_NAME}=? AND " +
                    "${MediaStore.Downloads.RELATIVE_PATH} LIKE ?",
                arrayOf(name, "${Environment.DIRECTORY_DOWNLOADS}/$folder%"),
            )
        } else {
            File(legacyDir(), name).delete()
        }
    }

    /** Opens Download/ApnaLedger in the Files app; falls back to Downloads. */
    private fun openFolder(): Boolean {
        val docUri: Uri = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:${Environment.DIRECTORY_DOWNLOADS}/$folder",
        )
        val attempts = listOf(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(docUri, "resource/folder")
            },
            Intent(DownloadManager.ACTION_VIEW_DOWNLOADS),
        )
        for (intent in attempts) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // try the next option
            }
        }
        return false
    }
}
