package com.example.native_core_video_player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.view.TextureRegistry

class VideoPlayer(
    private val context: Context,
    private val textureRegistry: TextureRegistry,
    private val eventSink: (Map<String, Any>) -> Unit
) {
    companion object {
        private const val TAG = "VideoPlayer"
    }
    
    private var exoPlayer: ExoPlayer? = null
    private var surfaceProducer: TextureRegistry.SurfaceProducer? = null
    private var surface: Surface? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var positionUpdateRunnable: Runnable? = null
    private var isInitialized = false
    private var pendingPlayCommand = false
    
    val textureId: Long
        get() = surfaceProducer?.id() ?: -1L

    fun initialize(source: String) {
        mainHandler.post {
            try {
                Log.d(TAG, "Initializing video player with source: $source")
                surfaceProducer = textureRegistry.createSurfaceProducer()
                
                surfaceProducer?.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                    override fun onSurfaceAvailable() {
                        Log.d(TAG, "Surface available, setting up player")
                        surface = surfaceProducer?.getSurface()
                        
                        // If player already exists, set the surface on it
                        val player = exoPlayer
                        if (player != null) {
                            val currentSurface = surface
                            if (currentSurface != null && currentSurface.isValid) {
                                player.setVideoSurface(currentSurface)
                                Log.d(TAG, "Surface set on existing player")
                            }
                        } else {
                            // Otherwise, set up the player
                            setupPlayer(source)
                        }
                    }

                    override fun onSurfaceDestroyed() {
                        Log.d(TAG, "Surface destroyed")
                        exoPlayer?.clearVideoSurface()
                        surface = null
                    }
                })
                
                // Set initial size to trigger surface creation
                // Use a default 16:9 aspect ratio, will be updated when video loads
                surfaceProducer?.setSize(1920, 1080)
            } catch (e: Exception) {
                Log.e(TAG, "Initialization error", e)
                sendError("initialization_error", e.message ?: "Failed to initialize")
            }
        }
    }

    private fun setupPlayer(source: String) {
        try {
            Log.d(TAG, "Setting up ExoPlayer for source: $source")
            
            // Create HTTP DataSource.Factory for network requests (required for HLS)
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                .setUserAgent("ExoPlayer")
                .setConnectTimeoutMs(DefaultHttpDataSource.DEFAULT_CONNECT_TIMEOUT_MILLIS)
                .setReadTimeoutMs(DefaultHttpDataSource.DEFAULT_READ_TIMEOUT_MILLIS)
                .setAllowCrossProtocolRedirects(true)
            
            Log.d(TAG, "Created HTTP DataSource.Factory for network requests")
            
            // Wrap HTTP DataSource in DefaultDataSource.Factory for proper ExoPlayer integration
            val dataSourceFactory = DefaultDataSource.Factory(context, httpDataSourceFactory)
            
            Log.d(TAG, "Created DefaultDataSource.Factory wrapper")
            
            // Create MediaSource.Factory by passing DataSource.Factory to constructor
            // This ensures proper initialization order for HLS support in Media3
            val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory)
            
            Log.d(TAG, "Created MediaSource.Factory with DataSource.Factory")
            
            exoPlayer = ExoPlayer.Builder(context)
                .setMediaSourceFactory(mediaSourceFactory)
                .build().apply {
                Log.d(TAG, "ExoPlayer built successfully")
                
                // Ensure surface is available before setting it
                val currentSurface = surface
                if (currentSurface != null && currentSurface.isValid) {
                    setVideoSurface(currentSurface)
                    Log.d(TAG, "Video surface set successfully")
                } else {
                    Log.w(TAG, "Surface not available or invalid, will be set when available")
                }
                
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        val stateName = when (playbackState) {
                            Player.STATE_IDLE -> "IDLE"
                            Player.STATE_BUFFERING -> "BUFFERING"
                            Player.STATE_READY -> "READY"
                            Player.STATE_ENDED -> "ENDED"
                            else -> "UNKNOWN"
                        }
                        val playerDuration = this@VideoPlayer.duration
                        Log.d(TAG, "Playback state changed: $stateName, isPlaying: $isPlaying, playWhenReady: $playWhenReady, duration: $playerDuration")
                        
                        when (playbackState) {
                            Player.STATE_IDLE -> sendEvent("state", "idle")
                            Player.STATE_BUFFERING -> sendEvent("state", "buffering")
                            Player.STATE_READY -> {
                                // Initialize when ready, even if duration is not yet available
                                if (!isInitialized) {
                                    isInitialized = true
                                    sendEvent("initialized", mapOf(
                                        "duration" to playerDuration,
                                        "width" to videoSize.width,
                                        "height" to videoSize.height
                                    ))
                                    Log.d(TAG, "Player initialized with duration: $playerDuration, size: ${videoSize.width}x${videoSize.height}")
                                    // Start continuous position updates immediately when ready (like iOS)
                                    startPositionUpdates()
                                    // Execute pending play command if any
                                    if (pendingPlayCommand) {
                                        pendingPlayCommand = false
                                        Log.d(TAG, "Executing pending play command - setting playWhenReady to true")
                                        // Set playWhenReady to start playback
                                        // Note: "playing" state was already sent by play() method
                                        playWhenReady = true
                                        // Don't send state here - already sent by play() method
                                        // Just let the normal state update happen below
                                    }
                                }
                                // Send state based on actual playback state
                                sendEvent("state", if (isPlaying) "playing" else "paused")
                            }
                            Player.STATE_ENDED -> sendEvent("state", "completed")
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        Log.e(TAG, "Player error occurred", error)
                        Log.e(TAG, "Error code: ${error.errorCode}, Message: ${error.message}")
                        Log.e(TAG, "Error cause: ${error.cause}")
                        val errorMessage = "Playback error (code: ${error.errorCode}): ${error.message ?: "Unknown error"}"
                        sendError("playback_error", errorMessage)
                    }
                    
                    override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
                        if (videoSize.width > 0 && videoSize.height > 0) {
                            surfaceProducer?.setSize(videoSize.width, videoSize.height)
                        }
                    }
                })

                val mediaItem = MediaItem.fromUri(source)
                Log.d(TAG, "Created MediaItem from URI: $source")
                setMediaItem(mediaItem)
                Log.d(TAG, "Set MediaItem on player")
                prepare()
                Log.d(TAG, "Player prepared, ready to play")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Player setup error", e)
            sendError("player_setup_error", e.message ?: "Failed to setup player")
        }
    }

    fun play() {
        mainHandler.post {
            val player = exoPlayer
            Log.d(TAG, "play() called - player exists: ${player != null}, isInitialized: $isInitialized")
            
            // Always send "playing" state immediately, just like iOS implementation
            // This provides instant UI feedback regardless of player initialization state
            sendEvent("state", "playing")
            
            if (player != null) {
                if (isInitialized) {
                    // Player is ready, start playback immediately
                    Log.d(TAG, "Starting playback - setting playWhenReady to true")
                    player.playWhenReady = true
                } else {
                    // Player not ready yet, queue the play command
                    pendingPlayCommand = true
                    Log.d(TAG, "Play command queued, waiting for player to be ready")
                }
            } else {
                // Player doesn't exist yet, queue the play command
                pendingPlayCommand = true
                Log.d(TAG, "Play command queued, player not created yet")
            }
        }
    }

    fun pause() {
        mainHandler.post {
            Log.d(TAG, "pause() called")
            exoPlayer?.playWhenReady = false
            // Send paused state immediately, similar to iOS implementation
            sendEvent("state", "paused")
        }
    }

    fun seekTo(position: Long) {
        mainHandler.post {
            exoPlayer?.seekTo(position)
            // Send position update immediately after seek (like iOS)
            mainHandler.postDelayed({
                exoPlayer?.let { player ->
                    sendEvent("position", mapOf(
                        "position" to player.currentPosition,
                        "bufferedPosition" to player.bufferedPosition
                    ))
                }
            }, 100)
        }
    }

    fun setVolume(volume: Float) {
        mainHandler.post {
            exoPlayer?.volume = volume.coerceIn(0f, 1f)
        }
    }

    fun setPlaybackSpeed(speed: Float) {
        mainHandler.post {
            exoPlayer?.setPlaybackSpeed(speed)
        }
    }

    fun setLooping(looping: Boolean) {
        mainHandler.post {
            exoPlayer?.repeatMode = if (looping) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        }
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                exoPlayer?.let { player ->
                    sendEvent("position", mapOf(
                        "position" to player.currentPosition,
                        "bufferedPosition" to player.bufferedPosition
                    ))
                    mainHandler.postDelayed(this, 100)
                }
            }
        }
        mainHandler.post(positionUpdateRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let {
            mainHandler.removeCallbacks(it)
            positionUpdateRunnable = null
        }
    }

    private val duration: Long
        get() = exoPlayer?.duration?.takeIf { it != androidx.media3.common.C.TIME_UNSET } ?: 0L

    private val currentPosition: Long
        get() = exoPlayer?.currentPosition ?: 0L

    private val bufferedPosition: Long
        get() = exoPlayer?.bufferedPosition ?: 0L

    private val videoSize: androidx.media3.common.VideoSize
        get() = exoPlayer?.videoSize ?: androidx.media3.common.VideoSize.UNKNOWN

    fun dispose() {
        mainHandler.post {
            stopPositionUpdates()
            exoPlayer?.release()
            exoPlayer = null
            surfaceProducer?.release()
            surfaceProducer = null
            surface = null
        }
    }

    private fun sendEvent(event: String, data: Any) {
        eventSink(mapOf("event" to event, "data" to data))
    }

    private fun sendError(code: String, message: String) {
        eventSink(mapOf("event" to "error", "data" to mapOf("code" to code, "message" to message)))
    }
}
