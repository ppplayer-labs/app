package com.ppplayer.app

import android.content.Context
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.MediaStatus
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.common.images.WebImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.util.IdentityHashMap
import java.util.UUID
import java.util.concurrent.Executors

/** audio_service owns PPPlayer's one media session and notification. */
class PPPlayerCastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions = CastOptions.Builder()
        .setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)
        .setCastMediaOptions(CastMediaOptions.Builder().setMediaSessionEnabled(false).setNotificationOptions(null).build())
        .setResumeSavedSession(true)
        .setStopReceiverApplicationWhenEndingSession(false)
        .build()
    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? = null
}

/** Official mobile sender SDK behind a PPPlayer-owned, identity-stamped channel. */
class NetworkOutputsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private var sink: EventChannel.EventSink? = null
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var cast: CastContext? = null
    private var router: MediaRouter? = null
    private var scanning = false
    private var multicast: WifiManager.MulticastLock? = null
    private var attached = false
    private val routes = mutableMapOf<String, MediaRouter.RouteInfo>()
    private data class Stamp(val sessionId: String, val endpointId: String, var itemId: String = "")
    private val stamps = IdentityHashMap<CastSession, Stamp>()
    private var desiredStamp: Stamp? = null
    private var connectResult: MethodChannel.Result? = null
    private var connectDeadline: Runnable? = null
    private var mediaCallback: RemoteMediaClient.Callback? = null
    private var progressListener: RemoteMediaClient.ProgressListener? = null
    private var observedClient: RemoteMediaClient? = null
    private data class FileLease(val file: File, val temporary: Boolean)
    private val leases = mutableMapOf<String, FileLease>()
    private val selector = MediaRouteSelector.Builder().addControlCategory(
        CastMediaControlIntent.categoryForCast(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID)).build()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "com.ppplayer.app/network_outputs")
        events = EventChannel(binding.binaryMessenger, "com.ppplayer.app/network_output_events")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        attached = true
    }
    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) { sink = eventSink; emitDevices() }
    override fun onCancel(arguments: Any?) { sink = null }
    private fun emit(value: Map<String, Any?>) { if (attached) sink?.success(value) }

    private fun withCast(result: MethodChannel.Result, action: (CastContext) -> Unit) {
        cast?.let { action(it); return }
        CastContext.getSharedInstance(context, worker).addOnSuccessListener { ready ->
            if (!attached) { result.error("OUTPUT_UNAVAILABLE", "The sender is detached.", null); return@addOnSuccessListener }
            cast = ready
            router = MediaRouter.getInstance(context)
            ready.sessionManager.addSessionManagerListener(sessionListener, CastSession::class.java)
            action(ready)
        }.addOnFailureListener { result.error("CAST_UNAVAILABLE", "Google Play services Cast support is unavailable.", null) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformCapabilities" -> result.success(mapOf("googleCastAvailable" to true, "airPlayPickerAvailable" to false, "airPlayVerified" to false, "dlnaDiscoveryAvailable" to true))
            "setMulticastLock" -> {
                try {
                    if (call.argument<Boolean>("enabled") == true) {
                        if (multicast == null) multicast = (context.getSystemService(Context.WIFI_SERVICE) as WifiManager).createMulticastLock("ppplayer-output-discovery").apply { setReferenceCounted(false) }
                        if (multicast?.isHeld != true) multicast?.acquire()
                    } else if (multicast?.isHeld == true) multicast?.release()
                    result.success(null)
                } catch (_: Exception) { result.error("MULTICAST_UNAVAILABLE", "Wi-Fi multicast discovery is unavailable.", null) }
            }
            "acquireFileLease" -> acquireFile(call, result)
            "releaseFileLease" -> {
                val lease = synchronized(leases) { leases.remove(call.argument<String>("leaseId")) }
                if (lease?.temporary == true) lease.file.delete()
                result.success(null)
            }
            "startDiscovery" -> withCast(result) {
                if (!scanning) { scanning = true; router!!.addCallback(selector, routeCallback, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY) }
                refreshRoutes(); result.success(null)
            }
            "stopDiscovery" -> { if (scanning) router?.removeCallback(routeCallback); scanning = false; result.success(null) }
            "connect" -> withCast(result) { connect(call, result, it) }
            "disconnect" -> disconnect(call, result)
            "load" -> load(call, result)
            "play", "pause", "stop", "seek", "setVolume", "setMute" -> control(call, result)
            else -> result.notImplemented()
        }
    }

    private val routeCallback = object : MediaRouter.Callback() {
        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) { refreshRoutes() }
        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) { refreshRoutes() }
        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) { refreshRoutes() }
    }
    private fun refreshRoutes() {
        routes.clear()
        router?.routes?.filter { it.matchesSelector(selector) && it.isEnabled && !it.isDefault }?.forEach { route ->
            CastDevice.getFromBundle(route.extras)?.let { routes[it.deviceId] = route }
        }
        emitDevices()
    }
    private fun emitDevices() {
        emit(mapOf("event" to "devices", "kind" to "googleCast", "devices" to routes.map { (id, route) ->
            val device = CastDevice.getFromBundle(route.extras)
            mapOf("id" to id, "name" to route.name, "model" to device?.modelName, "audio" to true,
                "video" to (device?.hasCapability(CastDevice.CAPABILITY_VIDEO_OUT) == true))
        }))
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result, ready: CastContext) {
        val id = call.argument<String>("endpointId") ?: ""
        val sessionId = call.argument<String>("sessionId") ?: ""
        if (sessionId.isEmpty()) { result.error("INVALID_SESSION", "A session identity is required.", null); return }
        connectResult?.error("SUPERSEDED", "A newer output selection replaced this connection.", null)
        connectDeadline?.let { main.removeCallbacks(it) }
        desiredStamp = Stamp(sessionId, id)
        val existing = ready.sessionManager.currentCastSession
        if (existing?.isConnected == true && existing.castDevice?.deviceId == id) {
            stamps[existing] = desiredStamp!!; observe(existing); emitSession(existing, "connected"); result.success(null); return
        }
        val route = routes[id]
        if (route == null) { desiredStamp = null; result.error("DEVICE_UNAVAILABLE", "This Cast device is no longer available.", null); return }
        connectResult = result
        connectDeadline = Runnable {
            if (desiredStamp?.sessionId == sessionId) {
                connectResult?.error("CONNECT_TIMEOUT", "The Cast device did not connect in time.", null)
                connectResult = null; desiredStamp = null
                ready.sessionManager.endCurrentSession(false)
            }
        }.also { main.postDelayed(it, 20000) }
        router!!.selectRoute(route)
    }

    private fun bind(session: CastSession): Stamp? {
        stamps[session]?.let { return it }
        val desired = desiredStamp ?: return null
        if (session.castDevice?.deviceId != desired.endpointId) return null
        stamps[session] = desired
        return desired
    }
    private fun emitSession(session: CastSession, state: String, error: String? = null) {
        val stamp = stamps[session] ?: return
        emit(mapOf("event" to "session", "kind" to "googleCast", "sessionId" to stamp.sessionId,
            "endpointId" to stamp.endpointId, "itemId" to stamp.itemId, "state" to state, "error" to error))
    }
    private fun connected(session: CastSession) {
        val stamp = bind(session) ?: return
        if (desiredStamp?.sessionId != stamp.sessionId) return
        observe(session); emitSession(session, "connected")
        connectDeadline?.let { main.removeCallbacks(it) }; connectDeadline = null
        connectResult?.success(null); connectResult = null
    }
    private val sessionListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarting(session: CastSession) { bind(session); emitSession(session, "connecting") }
        override fun onSessionStarted(session: CastSession, id: String) { connected(session) }
        override fun onSessionStartFailed(session: CastSession, error: Int) { failed(session, "Cast connection failed ($error).") }
        override fun onSessionEnding(session: CastSession) { emitSession(session, "disconnecting") }
        override fun onSessionEnded(session: CastSession, error: Int) { emitSession(session, "disconnected"); stamps.remove(session); unobserve() }
        override fun onSessionResuming(session: CastSession, id: String) { bind(session); emitSession(session, "connecting") }
        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) { connected(session) }
        override fun onSessionResumeFailed(session: CastSession, error: Int) { failed(session, "Cast reconnection failed ($error).") }
        override fun onSessionSuspended(session: CastSession, reason: Int) { emitSession(session, "suspended") }
    }
    private fun failed(session: CastSession, error: String) {
        val stamp = bind(session)
        emitSession(session, "disconnected", error)
        if (stamp?.sessionId == desiredStamp?.sessionId) {
            connectResult?.error("CONNECT_FAILED", error, null); connectResult = null
            connectDeadline?.let { main.removeCallbacks(it) }; connectDeadline = null
        }
    }

    private fun observe(session: CastSession) {
        unobserve()
        val client = session.remoteMediaClient ?: return
        val callback = object : RemoteMediaClient.Callback() {
            override fun onStatusUpdated() { emitStatus(session) }
            override fun onMetadataUpdated() { emitStatus(session) }
        }
        val progress = RemoteMediaClient.ProgressListener { _, _ -> emitStatus(session) }
        observedClient = client; mediaCallback = callback; progressListener = progress
        client.registerCallback(callback); client.addProgressListener(progress, 1000)
        emitStatus(session)
    }
    private fun unobserve() {
        mediaCallback?.let { observedClient?.unregisterCallback(it) }
        progressListener?.let { observedClient?.removeProgressListener(it) }
        mediaCallback = null; progressListener = null; observedClient = null
    }
    private fun emitStatus(session: CastSession) {
        val stamp = stamps[session] ?: return
        val client = session.remoteMediaClient ?: return
        val status = client.mediaStatus ?: return
        val media = status.mediaInfo
        val data = media?.customData
        // Receiver-echoed identity prevents a late old-media status from being
        // labeled as the newly requested item while LOAD is still in flight.
        val itemId = if (data?.optString("ppSessionId") == stamp.sessionId) data.optString("ppItemId") else ""
        val state = when (status.playerState) {
            MediaStatus.PLAYER_STATE_PLAYING -> "playing"
            MediaStatus.PLAYER_STATE_PAUSED -> "paused"
            MediaStatus.PLAYER_STATE_BUFFERING -> "buffering"
            MediaStatus.PLAYER_STATE_IDLE -> if (status.idleReason == MediaStatus.IDLE_REASON_FINISHED) "ended" else "stopped"
            else -> "idle"
        }
        emit(mapOf("event" to "status", "kind" to "googleCast", "sessionId" to stamp.sessionId,
            "endpointId" to stamp.endpointId, "itemId" to itemId, "state" to state,
            "positionMs" to client.approximateStreamPosition, "durationMs" to (media?.streamDuration ?: 0),
            "isLive" to (media?.streamType == MediaInfo.STREAM_TYPE_LIVE), "volume" to session.volume,
            "muted" to session.isMute, "seek" to status.isMediaCommandSupported(MediaStatus.COMMAND_SEEK),
            "pause" to status.isMediaCommandSupported(MediaStatus.COMMAND_PAUSE)))
    }

    private fun active(call: MethodCall, result: MethodChannel.Result, requireItem: Boolean): CastSession? {
        val session = cast?.sessionManager?.currentCastSession
        val stamp = session?.let { stamps[it] }
        if (session?.isConnected != true || stamp?.sessionId != call.argument<String>("sessionId") ||
            (requireItem && stamp?.itemId != call.argument<String>("itemId"))) {
            result.error("STALE_SESSION", "This playback session is no longer active.", null); return null
        }
        return session
    }
    private fun load(call: MethodCall, result: MethodChannel.Result) {
        val session = active(call, result, false) ?: return
        val stamp = stamps[session]!!
        val itemId = call.argument<String>("itemId") ?: ""
        val item = call.argument<Map<String, Any?>>("item") ?: emptyMap()
        val uri = Uri.parse(item["uri"] as? String ?: "")
        if (itemId.isEmpty() || uri.scheme !in listOf("http", "https")) { result.error("INVALID_MEDIA", "A reachable media URL is required.", null); return }
        if (uri.host?.lowercase()?.let { it == "youtu.be" || it == "youtube.com" || it.endsWith(".youtube.com") || it.endsWith(".youtube-nocookie.com") } == true) {
            result.error("UNSUPPORTED_SOURCE", "YouTube iframe media cannot use the generic Cast receiver.", null); return
        }
        val metadata = MediaMetadata(if (item["isVideo"] == true) MediaMetadata.MEDIA_TYPE_MOVIE else MediaMetadata.MEDIA_TYPE_MUSIC_TRACK)
        metadata.putString(MediaMetadata.KEY_TITLE, item["title"] as? String ?: "")
        (item["artist"] as? String)?.let { metadata.putString(MediaMetadata.KEY_ARTIST, it) }
        (item["album"] as? String)?.let { metadata.putString(MediaMetadata.KEY_ALBUM_TITLE, it) }
        (item["artworkUri"] as? String)?.let { metadata.addImage(WebImage(Uri.parse(it))) }
        val live = item["isLive"] == true
        val infoBuilder = MediaInfo.Builder(uri.toString()).setContentType(item["mimeType"] as? String ?: "application/octet-stream")
            .setStreamType(if (live) MediaInfo.STREAM_TYPE_LIVE else MediaInfo.STREAM_TYPE_BUFFERED)
            .setMetadata(metadata).setCustomData(JSONObject().put("ppSessionId", stamp.sessionId).put("ppItemId", itemId))
        if (!live) (item["durationMs"] as? Number)?.let { infoBuilder.setStreamDuration(it.toLong()) }
        val request = MediaLoadRequestData.Builder().setMediaInfo(infoBuilder.build())
            .setAutoplay(call.argument<Boolean>("autoplay") != false)
            .setCurrentTime(if (live) 0 else call.argument<Number>("positionMs")?.toLong() ?: 0).build()
        session.remoteMediaClient!!.load(request).setResultCallback { outcome ->
            if (stamps[session] !== stamp || desiredStamp?.sessionId != stamp.sessionId) {
                result.error("STALE_SESSION", "A newer output selection replaced this load.", null)
            } else if (outcome.status.isSuccess) {
                stamp.itemId = itemId; result.success(mapOf("success" to true)); emitStatus(session)
            } else result.success(mapOf("success" to false, "error" to "The Cast receiver rejected this media (${outcome.status.statusCode})."))
        }
    }
    private fun control(call: MethodCall, result: MethodChannel.Result) {
        val session = active(call, result, true) ?: return
        val client = session.remoteMediaClient!!
        try {
            if (call.method == "setVolume" || call.method == "setMute") {
                if (call.method == "setVolume") session.volume = (call.argument<Number>("volume")?.toDouble() ?: 1.0).coerceIn(0.0, 1.0)
                else session.isMute = call.argument<Boolean>("muted") == true
                result.success(null); emitStatus(session); return
            }
            val pending = when (call.method) {
                "play" -> client.play()
                "pause" -> client.pause()
                "stop" -> client.stop()
                else -> {
                    if (client.mediaInfo?.streamType == MediaInfo.STREAM_TYPE_LIVE) { result.error("UNSUPPORTED_OPERATION", "Live streams cannot seek.", null); return }
                    client.seek(MediaSeekOptions.Builder().setPosition((call.argument<Number>("positionMs")?.toLong() ?: 0).coerceAtLeast(0)).build())
                }
            }
            pending.setResultCallback { outcome ->
                if (outcome.status.isSuccess) result.success(null)
                else result.error("REMOTE_COMMAND_FAILED", "The Cast receiver rejected the command (${outcome.status.statusCode}).", null)
            }
        } catch (_: Exception) { result.error("REMOTE_COMMAND_FAILED", "The Cast device could not accept this command.", null) }
    }
    private fun disconnect(call: MethodCall, result: MethodChannel.Result) {
        val session = active(call, result, false) ?: return
        val stamp = stamps[session]!!
        val stop = call.argument<Boolean>("stopPlayback") == true
        if (stop) session.remoteMediaClient?.stop()
        cast!!.sessionManager.endCurrentSession(stop)
        emitSession(session, "disconnected")
        stamps.remove(session); unobserve()
        if (desiredStamp === stamp) desiredStamp = null
        result.success(null)
    }

    private fun acquireFile(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri") ?: "")
        worker.execute {
            var temporary: File? = null
            try {
                if (synchronized(leases) { leases.size } >= 8) throw IllegalStateException("Too many active file leases.")
                val file = when (uri.scheme) {
                    "file" -> File(uri.path ?: "").canonicalFile
                    "content" -> {
                        // Bound disk use and memory. No sender-only content URI is
                        // exposed to a remote receiver or converted into a path.
                        val maxBytes = 2L * 1024 * 1024 * 1024
                        val descriptor = context.contentResolver.openAssetFileDescriptor(uri, "r") ?: throw IllegalStateException("The selected document cannot be opened.")
                        descriptor.use { asset ->
                            if (asset.length > maxBytes) throw IllegalStateException("Selected document exceeds the 2 GiB remote-playback copy limit.")
                            val dir = File(context.cacheDir, "network-output-media").apply { mkdirs() }
                            val copy = File.createTempFile("media-", ".bin", dir)
                            temporary = copy
                            asset.createInputStream().use { input -> copy.outputStream().use { output ->
                                val buffer = ByteArray(64 * 1024); var total = 0L
                                while (true) {
                                    val count = input.read(buffer); if (count < 0) break
                                    total += count; if (total > maxBytes) throw IllegalStateException("Selected document exceeds the 2 GiB remote-playback copy limit.")
                                    output.write(buffer, 0, count)
                                }
                            } }
                            copy.canonicalFile
                        }
                    }
                    else -> throw IllegalArgumentException("Unsupported local media URI.")
                }
                if (!file.isFile || !file.canRead()) throw IllegalStateException("The selected file cannot be read.")
                val id = UUID.randomUUID().toString()
                synchronized(leases) { leases[id] = FileLease(file, temporary != null) }
                main.post {
                    if (attached) result.success(mapOf("leaseId" to id, "canonicalPath" to file.path))
                    else { synchronized(leases) { leases.remove(id) }; temporary?.delete() }
                }
            } catch (error: Exception) {
                temporary?.delete()
                main.post { if (attached) result.error("FILE_ACCESS", error.message ?: "Local media access failed.", null) }
            }
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        attached = false; methods.setMethodCallHandler(null); events.setStreamHandler(null); sink = null
        router?.removeCallback(routeCallback); cast?.sessionManager?.removeSessionManagerListener(sessionListener, CastSession::class.java)
        unobserve(); connectDeadline?.let { main.removeCallbacks(it) }; connectResult?.error("OUTPUT_UNAVAILABLE", "The sender is detached.", null); connectResult = null
        if (multicast?.isHeld == true) multicast?.release()
        synchronized(leases) { leases.values.filter { it.temporary }.forEach { it.file.delete() }; leases.clear() }
        worker.shutdown()
    }
}
