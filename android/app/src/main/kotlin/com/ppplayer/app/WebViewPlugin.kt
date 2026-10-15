package com.ppplayer.app

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.util.Log

class WebViewPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val CHANNEL = "com.ppplayer.app/headless_webview"
        private var methodChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())
        
        fun sendReadyEvent() {
            mainHandler.post {
                methodChannel?.invokeMethod("onReady", null)
            }
        }
        
        fun sendStateChange(state: Int, commandId: Int) {
            mainHandler.post {
                methodChannel?.invokeMethod("onStateChange", mapOf(
                    "state" to state,
                    "commandId" to commandId
                ))
            }
        }
        
        fun sendError(error: Int) {
            mainHandler.post {
                methodChannel?.invokeMethod("onError", error)
            }
        }
        
        fun sendPosition(currentTime: Double, duration: Double) {
            mainHandler.post {
                methodChannel?.invokeMethod("onPosition", mapOf(
                    "currentTime" to currentTime,
                    "duration" to duration
                ))
            }
        }
    }

    private var context: Context? = null
    private enum class ServiceOwner { NONE, CHROMIUM, LEGACY }
    // Reserve before startForegroundService: onStartCommand runs asynchronously.
    private var serviceOwner = ServiceOwner.NONE

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startChromiumService" -> {
                if (serviceOwner == ServiceOwner.LEGACY || CustomWebViewService.instance?.ownsWebView == true) {
                    result.error("BUSY", "Legacy playback service already owns a WebView", null)
                    return
                }
                if (serviceOwner == ServiceOwner.CHROMIUM) { result.success(null); return }
                val appContext = context ?: return result.error("DETACHED", "Engine detached", null)
                serviceOwner = ServiceOwner.CHROMIUM
                val intent = Intent(appContext, CustomWebViewService::class.java).apply {
                    putExtra(CustomWebViewService.EXTRA_CHROMIUM_PLAYER, true)
                }
                try {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O)
                        context?.startForegroundService(intent)
                    else context?.startService(intent)
                    awaitChromiumService(result, appContext)
                } catch (e: Exception) {
                    serviceOwner = ServiceOwner.NONE
                    result.error("SERVICE_START_FAILED", e.message, null)
                }
            }
            "stopChromiumService" -> {
                if (serviceOwner == ServiceOwner.CHROMIUM) {
                    context?.stopService(Intent(context, CustomWebViewService::class.java))
                    serviceOwner = ServiceOwner.NONE
                }
                result.success(null)
            }
            "chromiumServiceState" -> {
                result.success(mapOf("running" to (CustomWebViewService.instance != null),
                    "interactive" to ((context?.getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isInteractive == true),
                    "chromiumPlayer" to (CustomWebViewService.instance?.chromiumPlayer == true),
                    "ownsWebView" to (CustomWebViewService.instance?.ownsWebView == true)))
            }
            "startService" -> {
                if (serviceOwner == ServiceOwner.CHROMIUM) {
                    result.error("BUSY", "Chromium playback already owns the service", null)
                    return
                }
                if (serviceOwner == ServiceOwner.LEGACY) { result.success(null); return }
                val appContext = context ?: return result.error("DETACHED", "Engine detached", null)
                serviceOwner = ServiceOwner.LEGACY
                try {
                    val intent = Intent(appContext, CustomWebViewService::class.java)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O)
                        appContext.startForegroundService(intent)
                    else appContext.startService(intent)
                    result.success(null)
                } catch (e: Exception) {
                    serviceOwner = ServiceOwner.NONE
                    result.error("SERVICE_START_FAILED", e.message, null)
                }
            }
            "stopService" -> {
                if (serviceOwner == ServiceOwner.LEGACY) {
                    context?.stopService(Intent(context, CustomWebViewService::class.java))
                    serviceOwner = ServiceOwner.NONE
                }
                result.success(null)
            }
            "prepareVideo" -> {
                val args = call.arguments as Map<*, *>
                val videoId = args["videoId"] as String
                val startSeconds = args["startSeconds"] as Double
                val commandId = (args["commandId"] as? Int) ?: 0
                CustomWebViewService.instance?.prepareVideo(videoId, startSeconds, commandId)
                result.success(null)
            }
            "loadVideo" -> {
                val videoId = call.argument<String>("videoId") ?: return result.error("INVALID", "Missing videoId", null)
                val startSeconds = call.argument<Double>("startSeconds") ?: 0.0
                val commandId = call.argument<Int>("commandId") ?: 0
                CustomWebViewService.instance?.loadVideo(videoId, startSeconds, commandId)
                result.success(null)
            }
            "playVideo" -> {
                CustomWebViewService.instance?.playVideo()
                result.success(null)
            }
            "pauseVideo" -> {
                CustomWebViewService.instance?.pauseVideo()
                result.success(null)
            }
            "seekTo" -> {
                val seconds = call.argument<Double>("seconds") ?: 0.0
                CustomWebViewService.instance?.seekTo(seconds)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Int>("volume") ?: 100
                CustomWebViewService.instance?.setVolume(volume)
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun awaitChromiumService(result: Result, appContext: Context, attempts: Int = 20) {
        if (serviceOwner != ServiceOwner.CHROMIUM) {
            result.error("SERVICE_STOPPED", "Service ownership invalidated", null)
            return
        }
        val service = CustomWebViewService.instance
        if (service?.chromiumPlayer == true && !service.ownsWebView) {
            result.success(null)
            return
        }
        if (attempts == 0) {
            appContext.stopService(Intent(appContext, CustomWebViewService::class.java))
            serviceOwner = ServiceOwner.NONE
            result.error("SERVICE_START_TIMEOUT", "Chromium service did not become ready", null)
            return
        }
        mainHandler.postDelayed({ awaitChromiumService(result, appContext, attempts - 1) }, 250)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (serviceOwner != ServiceOwner.NONE) context?.stopService(Intent(context, CustomWebViewService::class.java))
        serviceOwner = ServiceOwner.NONE
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        context = null
    }
}
