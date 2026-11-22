package com.ppplayer.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LocalFilesPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    companion object {
        private const val REQUEST_CODE_OPEN_DOCUMENT_TREE = 44021
        private val AUDIO_EXTENSIONS = setOf(
            ".mp3", ".m4a", ".flac", ".wav", ".aac", ".ogg", ".opus", ".wma", ".aiff", ".aif", ".alac", ".oga",
        )
        private val VIDEO_EXTENSIONS = setOf(
            ".mp4", ".m4v", ".mkv", ".webm", ".mov", ".avi", ".3gp", ".ts", ".m2ts", ".flv", ".wmv", ".ogv", ".mpg", ".mpeg",
        )
    }

    private var context: Context? = null
    private var methodChannel: MethodChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingTreeResult: Result? = null
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "com.ppplayer.app/local_files")
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        pendingTreeResult?.success(null)
        pendingTreeResult = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_OPEN_DOCUMENT_TREE) return false
        val result = pendingTreeResult ?: return true
        pendingTreeResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return true
        }
        val treeUri = data?.data
        if (treeUri == null) {
            result.success(null)
            return true
        }
        val flags = (data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
        val persistFlags = if ((flags and Intent.FLAG_GRANT_READ_URI_PERMISSION) != 0) {
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        } else {
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        try {
            context?.contentResolver?.takePersistableUriPermission(treeUri, persistFlags)
        } catch (_: Exception) {
            // Some document providers reject persistable grants; session access still succeeds.
        }
        result.success(treeUri.toString())
        return true
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pickDocumentTree" -> {
                val activity = activityBinding?.activity
                if (activity == null) {
                    result.error("NO_ACTIVITY", "No active Activity available to open document tree picker", null)
                    return
                }
                if (pendingTreeResult != null) {
                    result.error("IN_PROGRESS", "Document tree picker is already open", null)
                    return
                }
                pendingTreeResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    addFlags(
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                            Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
                    )
                }
                try {
                    activity.startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
                } catch (e: Exception) {
                    pendingTreeResult = null
                    result.error("PICKER_ERROR", e.message, null)
                }
            }
            "canReadContentUri" -> {
                val uriString = call.argument<String>("uri")
                if (uriString == null) {
                    result.error("INVALID", "Missing uri", null)
                    return
                }
                val uri = Uri.parse(uriString)
                val canRead = try {
                    context?.contentResolver?.openInputStream(uri)?.use { true } ?: false
                } catch (e: Exception) {
                    false
                }
                result.success(canRead)
            }
            "copyToTemp" -> {
                val uriString = call.argument<String>("uri")
                val requestedName = call.argument<String>("name")
                if (uriString == null) {
                    result.error("INVALID", "Missing uri", null)
                    return
                }
                val appContext = context
                if (appContext == null) {
                    result.error("DETACHED", "Plugin is detached", null)
                    return
                }
                coroutineScope.launch {
                    val tempPath = withContext(Dispatchers.IO) {
                        try {
                            val uri = Uri.parse(uriString)
                            val docName = try {
                                DocumentFile.fromSingleUri(appContext, uri)?.name
                            } catch (_: Exception) {
                                null
                            }
                            val rawName = docName?.takeIf { it.isNotBlank() }
                                ?: requestedName?.substringAfterLast('/')?.takeIf { it.isNotBlank() }
                                ?: "media.tmp"
                            val safeName = rawName.replace(Regex("[^A-Za-z0-9._-]"), "_")
                            val outFile = File(appContext.cacheDir, "ppplayer_saf_${System.nanoTime()}_$safeName")
                            appContext.contentResolver.openInputStream(uri)?.use { input ->
                                FileOutputStream(outFile).use { output ->
                                    input.copyTo(output)
                                }
                            } ?: return@withContext null
                            outFile.absolutePath
                        } catch (_: Exception) {
                            null
                        }
                    }
                    if (context != null) {
                        result.success(tempPath)
                    }
                }
            }
            "listAudioFiles" -> {
                val treeUriString = call.argument<String>("treeUri")
                val recursive = call.argument<Boolean>("recursive") ?: true
                val scope = call.argument<String>("scope") ?: "audio"
                if (treeUriString == null) {
                    result.error("INVALID", "Missing treeUri", null)
                    return
                }

                val appContext = context
                if (appContext == null) {
                    result.error("DETACHED", "Plugin is detached", null)
                    return
                }

                coroutineScope.launch {
                    val files = withContext(Dispatchers.IO) {
                        val treeUri = Uri.parse(treeUriString)
                        val docTree = try {
                            DocumentFile.fromTreeUri(appContext, treeUri)
                        } catch (e: Exception) {
                            null
                        }
                        val resultList = mutableListOf<String>()
                        if (docTree != null && docTree.isDirectory) {
                            scanDirectory(docTree, recursive, scope, resultList)
                        }
                        resultList
                    }
                    if (context != null) {
                        result.success(files)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun scanDirectory(
        dir: DocumentFile,
        recursive: Boolean,
        scope: String,
        resultList: MutableList<String>,
    ) {
        val includeAudio = scope == "audio" || scope == "both"
        val includeVideo = scope == "video" || scope == "both"
        val files = dir.listFiles()
        for (file in files) {
            if (file.isDirectory) {
                if (recursive) {
                    scanDirectory(file, recursive, scope, resultList)
                }
            } else {
                val mimeType = file.type?.lowercase() ?: ""
                val name = file.name?.lowercase() ?: ""
                val isAudio = mimeType.startsWith("audio/") || AUDIO_EXTENSIONS.any { name.endsWith(it) }
                val isVideo = mimeType.startsWith("video/") || VIDEO_EXTENSIONS.any { name.endsWith(it) }
                if ((includeAudio && isAudio) || (includeVideo && isVideo)) {
                    resultList.add(file.uri.toString())
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        coroutineScope.cancel()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        pendingTreeResult = null
        context = null
    }
}
