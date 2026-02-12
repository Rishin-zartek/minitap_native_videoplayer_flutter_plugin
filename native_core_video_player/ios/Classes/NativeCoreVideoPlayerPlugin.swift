import Flutter
import UIKit

public class NativeCoreVideoPlayerPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var textureRegistry: FlutterTextureRegistry?
    private var videoPlayer: VideoPlayer?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "native_core_video_player", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "native_core_video_player/events", binaryMessenger: registrar.messenger())
        
        let instance = NativeCoreVideoPlayerPlugin()
        instance.methodChannel = methodChannel
        instance.eventChannel = eventChannel
        instance.textureRegistry = registrar.textures()
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let source = args["source"] as? String,
                  let textureRegistry = textureRegistry else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Source is required", details: nil))
                return
            }
            
            videoPlayer?.dispose()
            videoPlayer = VideoPlayer(textureRegistry: textureRegistry) { [weak self] event in
                self?.eventSink?(event)
            }
            
            videoPlayer?.initialize(source: source)
            result(videoPlayer?.getTextureId())
            
        case "play":
            videoPlayer?.play()
            result(nil)
            
        case "pause":
            videoPlayer?.pause()
            result(nil)
            
        case "seekTo":
            guard let args = call.arguments as? [String: Any],
                  let position = args["position"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Position is required", details: nil))
                return
            }
            videoPlayer?.seekTo(position: position)
            result(nil)
            
        case "setVolume":
            guard let args = call.arguments as? [String: Any],
                  let volume = args["volume"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Volume is required", details: nil))
                return
            }
            videoPlayer?.setVolume(volume: Float(volume))
            result(nil)
            
        case "setPlaybackSpeed":
            guard let args = call.arguments as? [String: Any],
                  let speed = args["speed"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Speed is required", details: nil))
                return
            }
            videoPlayer?.setPlaybackSpeed(speed: Float(speed))
            result(nil)
            
        case "setLooping":
            guard let args = call.arguments as? [String: Any],
                  let looping = args["looping"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Looping is required", details: nil))
                return
            }
            videoPlayer?.setLooping(looping: looping)
            result(nil)
            
        case "dispose":
            videoPlayer?.dispose()
            videoPlayer = nil
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension NativeCoreVideoPlayerPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
