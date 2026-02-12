package com.example.native_core_video_player

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

class NativeCoreVideoPlayerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private lateinit var textureRegistry: TextureRegistry
    private var activity: Activity? = null
    private var videoPlayer: VideoPlayer? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        textureRegistry = flutterPluginBinding.textureRegistry
        
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_core_video_player")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "native_core_video_player/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                val source = call.argument<String>("source")
                if (source == null) {
                    result.error("INVALID_ARGUMENT", "Source is required", null)
                    return
                }
                
                videoPlayer?.dispose()
                videoPlayer = VideoPlayer(context, textureRegistry) { event ->
                    eventSink?.success(event)
                }
                
                videoPlayer?.initialize(source)
                result.success(videoPlayer?.textureId)
            }
            "play" -> {
                videoPlayer?.play()
                result.success(null)
            }
            "pause" -> {
                videoPlayer?.pause()
                result.success(null)
            }
            "seekTo" -> {
                val position = call.argument<Number>("position")?.toLong()
                if (position == null) {
                    result.error("INVALID_ARGUMENT", "Position is required", null)
                    return
                }
                videoPlayer?.seekTo(position)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Number>("volume")?.toFloat()
                if (volume == null) {
                    result.error("INVALID_ARGUMENT", "Volume is required", null)
                    return
                }
                videoPlayer?.setVolume(volume)
                result.success(null)
            }
            "setPlaybackSpeed" -> {
                val speed = call.argument<Number>("speed")?.toFloat()
                if (speed == null) {
                    result.error("INVALID_ARGUMENT", "Speed is required", null)
                    return
                }
                videoPlayer?.setPlaybackSpeed(speed)
                result.success(null)
            }
            "setLooping" -> {
                val looping = call.argument<Boolean>("looping")
                if (looping == null) {
                    result.error("INVALID_ARGUMENT", "Looping is required", null)
                    return
                }
                videoPlayer?.setLooping(looping)
                result.success(null)
            }
            "dispose" -> {
                videoPlayer?.dispose()
                videoPlayer = null
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        videoPlayer?.dispose()
        videoPlayer = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        videoPlayer?.pause()
    }
}
