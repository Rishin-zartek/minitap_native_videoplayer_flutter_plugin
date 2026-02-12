package com.example.native_core_video_player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.view.TextureRegistry

class VideoPlayer(
    private val context: Context,
    private val textureRegistry: TextureRegistry,
    private val eventSink: (Map<String, Any>) -> Unit
) {
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
                surfaceProducer = textureRegistry.createSurfaceProducer()
                
                surfaceProducer?.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                    override fun onSurfaceAvailable() {
                        surface = surfaceProducer?.getSurface()
                        setupPlayer(source)
                    }

                    override fun onSurfaceDestroyed() {
                        surface = null
                    }
                })
                
                // Set initial size to trigger surface creation
                // Use a default 16:9 aspect ratio, will be updated when video loads
                surfaceProducer?.setSize(1920, 1080)
            } catch (e: Exception) {
                sendError("initialization_error", e.message ?: "Failed to initialize")
            }
        }
    }

    private fun setupPlayer(source: String) {
        try {
            exoPlayer = ExoPlayer.Builder(context).build().apply {
                setVideoSurface(surface)
                
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        when (playbackState) {
                            Player.STATE_IDLE -> sendEvent("state", "idle")
                            Player.STATE_BUFFERING -> sendEvent("state", "buffering")
                            Player.STATE_READY -> {
                                if (!isInitialized) {
                                    isInitialized = true
                                    sendEvent("initialized", mapOf(
                                        "duration" to duration,
                                        "width" to videoSize.width,
                                        "height" to videoSize.height
                                    ))
                                    // Execute pending play command if any
                                    if (pendingPlayCommand) {
                                        pendingPlayCommand = false
                                        play()
                                        return // play() will send the state event
                                    }
                                }
                                sendEvent("state", if (isPlaying) "playing" else "paused")
                            }
                            Player.STATE_ENDED -> sendEvent("state", "completed")
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        sendError("playback_error", error.message ?: "Unknown playback error")
                    }

                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        if (isPlaying) {
                            startPositionUpdates()
                        } else {
                            stopPositionUpdates()
                        }
                    }
                    
                    override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
                        if (videoSize.width > 0 && videoSize.height > 0) {
                            surfaceProducer?.setSize(videoSize.width, videoSize.height)
                        }
                    }
                })

                val mediaItem = MediaItem.fromUri(source)
                setMediaItem(mediaItem)
                prepare()
            }
        } catch (e: Exception) {
            sendError("player_setup_error", e.message ?: "Failed to setup player")
        }
    }

    fun play() {
        mainHandler.post {
            val player = exoPlayer
            if (player != null && isInitialized) {
                player.play()
                // Send playing state immediately, similar to iOS implementation
                sendEvent("state", "playing")
            } else {
                // Queue the play command to be executed when player is ready
                pendingPlayCommand = true
            }
        }
    }

    fun pause() {
        mainHandler.post {
            exoPlayer?.pause()
            // Send paused state immediately, similar to iOS implementation
            sendEvent("state", "paused")
        }
    }

    fun seekTo(position: Long) {
        mainHandler.post {
            exoPlayer?.seekTo(position)
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
