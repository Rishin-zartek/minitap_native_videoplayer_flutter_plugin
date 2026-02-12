import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'video_state.dart';

class NativeVideoController extends ValueNotifier<VideoPlayerValue> {
  static const MethodChannel _methodChannel = MethodChannel('native_core_video_player');
  static const EventChannel _eventChannel = EventChannel('native_core_video_player/events');

  int? _textureId;
  StreamSubscription? _eventSubscription;
  bool _isDisposed = false;

  NativeVideoController() : super(const VideoPlayerValue());

  int? get textureId => _textureId;

  Future<void> initialize(String source) async {
    if (_isDisposed) throw StateError('Controller is disposed');

    try {
      _textureId = await _methodChannel.invokeMethod<int>('initialize', {
        'source': source,
      });

      _setupEventListener();
    } catch (e) {
      value = value.copyWith(
        state: VideoState.error,
        errorCode: 'initialization_error',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void _setupEventListener() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (_isDisposed) return;
        _handleEvent(event);
      },
      onError: (dynamic error) {
        if (_isDisposed) return;
        value = value.copyWith(
          state: VideoState.error,
          errorCode: 'stream_error',
          errorMessage: error.toString(),
        );
      },
    );
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final eventType = event['event'] as String?;
    final data = event['data'];

    switch (eventType) {
      case 'initialized':
        if (data is Map) {
          final duration = data['duration'] as int?;
          final width = data['width'] as int?;
          final height = data['height'] as int?;
          value = value.copyWith(
            duration: Duration(milliseconds: duration ?? 0),
            width: width,
            height: height,
          );
        }
        break;

      case 'state':
        if (data is String) {
          final state = _parseState(data);
          value = value.copyWith(state: state);
        }
        break;

      case 'position':
        if (data is Map) {
          final position = data['position'] as int?;
          final bufferedPosition = data['bufferedPosition'] as int?;
          value = value.copyWith(
            position: Duration(milliseconds: position ?? 0),
            bufferedPosition: Duration(milliseconds: bufferedPosition ?? 0),
          );
        }
        break;

      case 'error':
        if (data is Map) {
          final code = data['code'] as String?;
          final message = data['message'] as String?;
          value = value.copyWith(
            state: VideoState.error,
            errorCode: code,
            errorMessage: message,
          );
        }
        break;
    }
  }

  VideoState _parseState(String state) {
    switch (state) {
      case 'idle':
        return VideoState.idle;
      case 'buffering':
        return VideoState.buffering;
      case 'playing':
        return VideoState.playing;
      case 'paused':
        return VideoState.paused;
      case 'completed':
        return VideoState.completed;
      default:
        return VideoState.idle;
    }
  }

  Future<void> play() async {
    if (_isDisposed) return;
    await _methodChannel.invokeMethod('play');
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await _methodChannel.invokeMethod('pause');
  }

  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;
    await _methodChannel.invokeMethod('seekTo', {
      'position': position.inMilliseconds,
    });
  }

  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _methodChannel.invokeMethod('setVolume', {
      'volume': clampedVolume,
    });
    value = value.copyWith(volume: clampedVolume);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_isDisposed) return;
    await _methodChannel.invokeMethod('setPlaybackSpeed', {
      'speed': speed,
    });
    value = value.copyWith(playbackSpeed: speed);
  }

  Future<void> setLooping(bool looping) async {
    if (_isDisposed) return;
    await _methodChannel.invokeMethod('setLooping', {
      'looping': looping,
    });
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing video player: $e');
    }

    super.dispose();
  }
}
