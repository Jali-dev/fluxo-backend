package com.fluxo.fluxo

import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadOptions
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.common.images.WebImage

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.fluxo.fluxo/cast"
    private var castContext: CastContext? = null

    private val sessionManagerListener = object : com.google.android.gms.cast.framework.SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            startCastService()
        }
        override fun onSessionEnded(session: CastSession, error: Int) {
            stopCastService()
        }
        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            startCastService()
        }
        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionEnding(session: CastSession) {}
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionStartFailed(session: CastSession, error: Int) {}
        override fun onSessionResumeFailed(session: CastSession, error: Int) {}
        override fun onSessionSuspended(session: CastSession, reason: Int) {}
    }

    private var pendingSharedUrl: String? = null
    private var flutterEngineInstance: FlutterEngine? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        try {
            castContext = CastContext.getSharedInstance(this)
        } catch (e: Exception) {
            // Log error but allow app to start
            android.util.Log.e("FluxoCast", "Error initializing CastContext", e)
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: android.content.Intent) {
        if (android.content.Intent.ACTION_SEND == intent.action && "text/plain" == intent.type) {
            intent.getStringExtra(android.content.Intent.EXTRA_TEXT)?.let { url ->
                pendingSharedUrl = url
                // If Flutter is ready, send it immediately
                flutterEngineInstance?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("onLinkReceived", url)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            castContext?.sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)
        } catch (e: Exception) {
            android.util.Log.e("FluxoCast", "Error adding session listener", e)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            castContext?.sessionManager?.removeSessionManagerListener(sessionManagerListener, CastSession::class.java)
        } catch (e: Exception) {
            android.util.Log.e("FluxoCast", "Error removing session listener", e)
        }
    }

    private fun startCastService() {
        val intent = android.content.Intent(this, FluxoCastService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopCastService() {
        val intent = android.content.Intent(this, FluxoCastService::class.java)
        stopService(intent)
    }



    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineInstance = flutterEngine

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(pendingSharedUrl)
                    pendingSharedUrl = null
                }
                "initCast" -> {
                    try {
                        castContext = CastContext.getSharedInstance(this)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("FluxoCast", "Init failed", e)
                        result.error("INIT_ERROR", e.message, null)
                    }
                }
                "loadMedia" -> {
                    val url = call.argument<String>("url")
                    val title = call.argument<String>("title")
                    val subtitle = call.argument<String>("subtitle")
                    val imageUrl = call.argument<String>("imageUrl")
                    val contentType = call.argument<String>("contentType")
                    val isLive = call.argument<Boolean>("isLive") ?: false

                    if (url != null) {
                        loadMedia(url, title, subtitle, imageUrl, contentType, isLive)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "URL is required", null)
                    }
                }
                "play" -> {
                    getRemoteMediaClient()?.play()
                    result.success(true)
                }
                "pause" -> {
                    getRemoteMediaClient()?.pause()
                    result.success(true)
                }
                "stop" -> {
                    getRemoteMediaClient()?.stop()
                    result.success(true)
                }
                "seek" -> {
                    val position = call.argument<Int>("position")?.toLong() ?: 0L
                    val mediaClient = getRemoteMediaClient()
                    if (mediaClient != null) {
                        val options = com.google.android.gms.cast.MediaSeekOptions.Builder()
                            .setPosition(position)
                            .build()
                        mediaClient.seek(options)
                        result.success(true)
                    } else {
                        result.error("NO_SESSION", "No active media session", null)
                    }
                }
                "setVolume" -> {
                    val volume = call.argument<Double>("volume") ?: 0.5
                    try {
                        castContext?.sessionManager?.currentCastSession?.volume = volume
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("VOLUME_ERROR", e.message, null)
                    }
                }
                "showRouteSelector" -> {
                    // This is a simplified way to trigger discovery/selection if needed.
                    // Ideally, use a PlatformView for the button.
                    // Or keep it simple: The Cast SDK manages the button visibility usually.
                    result.success(true) 
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getRemoteMediaClient(): com.google.android.gms.cast.framework.media.RemoteMediaClient? {
         if (castContext == null) {
             castContext = CastContext.getSharedInstance(this)
        }
        return castContext?.sessionManager?.currentCastSession?.remoteMediaClient
    }

    private fun loadMedia(url: String, title: String?, subtitle: String?, imageUrl: String?, contentType: String?, isLive: Boolean) {
        if (castContext == null) {
             castContext = CastContext.getSharedInstance(this)
        }
        
        val session = castContext?.sessionManager?.currentCastSession
        if (session == null || !session.isConnected) {
            Log.w("FluxoCast", "No active Cast session")
            return
        }

        val meta = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)
        meta.putString(MediaMetadata.KEY_TITLE, title ?: "Fluxo Video")
        meta.putString(MediaMetadata.KEY_SUBTITLE, subtitle ?: "Enviado desde Fluxo")
        if (!imageUrl.isNullOrEmpty()) {
            meta.addImage(WebImage(Uri.parse(imageUrl)))
        }

        // Determine stream type
        val streamType = if (isLive) MediaInfo.STREAM_TYPE_LIVE else MediaInfo.STREAM_TYPE_BUFFERED

        val mediaInfo = MediaInfo.Builder(url)
            .setStreamType(streamType)
            .setContentType(contentType ?: "video/mp4")
            .setMetadata(meta)
            .build()

        // Use MediaLoadOptions (Legacy but reliable)
        val options = MediaLoadOptions.Builder()
            .setAutoplay(true)
            .build()
            
        val remoteMediaClient = session.remoteMediaClient
        remoteMediaClient?.load(mediaInfo, options)
    }
}
