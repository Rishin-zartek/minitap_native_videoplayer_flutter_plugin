import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_core_video_player/src/video_controller.dart';
import 'package:native_core_video_player/src/video_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeVideoController', () {
    late NativeVideoController controller;
    late List<MethodCall> methodCalls;

    setUp(() {
      controller = NativeVideoController();
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_core_video_player'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'initialize':
              return 123; // Mock texture ID
            case 'play':
            case 'pause':
            case 'seekTo':
            case 'setVolume':
            case 'setPlaybackSpeed':
            case 'setLooping':
            case 'dispose':
              return null;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() async {
      await controller.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_core_video_player'),
        null,
      );
    });

    test('initializes with default values', () {
      expect(controller.value.state, VideoState.idle);
      expect(controller.value.position, Duration.zero);
      expect(controller.value.duration, Duration.zero);
      expect(controller.textureId, null);
    });

    test('initialize sets texture ID and calls native method', () async {
      await controller.initialize('https://example.com/video.mp4');
      
      expect(controller.textureId, 123);
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'initialize');
      expect(methodCalls[0].arguments['source'], 'https://example.com/video.mp4');
    });

    test('initialize supports HLS streaming URLs', () async {
      await controller.initialize('https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8');
      
      expect(controller.textureId, 123);
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'initialize');
      expect(methodCalls[0].arguments['source'], 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8');
    });

    test('initialize handles errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_core_video_player'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        },
      );

      try {
        await controller.initialize('https://example.com/video.mp4');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<PlatformException>());
      }

      expect(controller.value.state, VideoState.error);
      expect(controller.value.errorCode, 'initialization_error');
      expect(controller.value.errorMessage, contains('Test error'));
    });

    test('initialize throws StateError when disposed', () async {
      await controller.dispose();
      
      expect(
        () => controller.initialize('https://example.com/video.mp4'),
        throwsStateError,
      );
    });

    test('play calls native method', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.play();
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'play');
    });

    test('play does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.play();
      
      expect(methodCalls.length, 0);
    });

    test('pause calls native method', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.pause();
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'pause');
    });

    test('pause does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.pause();
      
      expect(methodCalls.length, 0);
    });

    test('seekTo calls native method with position', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.seekTo(const Duration(seconds: 30));
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'seekTo');
      expect(methodCalls[0].arguments['position'], 30000);
    });

    test('seekTo does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.seekTo(const Duration(seconds: 30));
      
      expect(methodCalls.length, 0);
    });

    test('setVolume calls native method and updates value', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.setVolume(0.5);
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'setVolume');
      expect(methodCalls[0].arguments['volume'], 0.5);
      expect(controller.value.volume, 0.5);
    });

    test('setVolume clamps value between 0 and 1', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.setVolume(1.5);
      expect(controller.value.volume, 1.0);
      
      await controller.setVolume(-0.5);
      expect(controller.value.volume, 0.0);
    });

    test('setVolume does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.setVolume(0.5);
      
      expect(methodCalls.length, 0);
    });

    test('setPlaybackSpeed calls native method and updates value', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.setPlaybackSpeed(1.5);
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'setPlaybackSpeed');
      expect(methodCalls[0].arguments['speed'], 1.5);
      expect(controller.value.playbackSpeed, 1.5);
    });

    test('setPlaybackSpeed does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.setPlaybackSpeed(1.5);
      
      expect(methodCalls.length, 0);
    });

    test('setLooping calls native method and updates value', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.setLooping(true);
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'setLooping');
      expect(methodCalls[0].arguments['looping'], true);
      expect(controller.value.isLooping, true);
    });

    test('setLooping does nothing when disposed', () async {
      await controller.dispose();
      methodCalls.clear();
      
      await controller.setLooping(true);
      
      expect(methodCalls.length, 0);
    });



    test('dispose calls native method and cancels subscription', () async {
      await controller.initialize('https://example.com/video.mp4');
      methodCalls.clear();
      
      await controller.dispose();
      
      expect(methodCalls.any((call) => call.method == 'dispose'), true);
    });

    test('dispose can be called multiple times safely', () async {
      await controller.initialize('https://example.com/video.mp4');
      
      await controller.dispose();
      await controller.dispose();
      
      // Should not throw
    });

    test('dispose handles errors gracefully', () async {
      await controller.initialize('https://example.com/video.mp4');
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_core_video_player'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'dispose') {
            throw PlatformException(code: 'ERROR', message: 'Dispose error');
          }
          return null;
        },
      );

      // Should not throw
      await controller.dispose();
    });

    group('Event handling', () {
      late StreamController<dynamic> eventStreamController;

      setUp(() {
        eventStreamController = StreamController<dynamic>.broadcast();
        
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          const EventChannel('native_core_video_player/events'),
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink events) {
              eventStreamController.stream.listen(
                events.success,
                onError: (dynamic error) => events.error(
                  code: 'ERROR',
                  message: error.toString(),
                ),
                onDone: events.endOfStream,
              );
            },
            onCancel: (Object? arguments) {},
          ),
        );
      });

      tearDown(() {
        eventStreamController.close();
      });

      test('handles initialized event', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'initialized',
          'data': {
            'duration': 120000,
            'width': 1920,
            'height': 1080,
          },
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.duration, const Duration(milliseconds: 120000));
        expect(controller.value.width, 1920);
        expect(controller.value.height, 1080);
      });

      test('handles state event - playing', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'playing',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.playing);
      });

      test('handles state event - paused', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'paused',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.paused);
      });

      test('handles state event - buffering', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'buffering',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.buffering);
      });

      test('handles state event - completed', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'completed',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.completed);
      });

      test('handles state event - idle', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'idle',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.idle);
      });

      test('handles state event - unknown state defaults to idle', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'state',
          'data': 'unknown_state',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.idle);
      });

      test('handles position event', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'position',
          'data': {
            'position': 30000,
            'bufferedPosition': 45000,
          },
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.position, const Duration(milliseconds: 30000));
        expect(controller.value.bufferedPosition, const Duration(milliseconds: 45000));
      });

      test('handles error event', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'error',
          'data': {
            'code': 'PLAYBACK_ERROR',
            'message': 'Failed to play video',
          },
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.error);
        expect(controller.value.errorCode, 'PLAYBACK_ERROR');
        expect(controller.value.errorMessage, 'Failed to play video');
      });

      test('ignores events when disposed', () async {
        await controller.initialize('https://example.com/video.mp4');
        await controller.dispose();
        
        final initialValue = controller.value;
        
        eventStreamController.add({
          'event': 'state',
          'data': 'playing',
        });

        await Future.delayed(const Duration(milliseconds: 100));

        // Value should not change after disposal
        expect(controller.value, initialValue);
      });

      test('handles stream errors', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.addError('Stream error');

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.state, VideoState.error);
        expect(controller.value.errorCode, 'stream_error');
        expect(controller.value.errorMessage, contains('Stream error'));
      });

      test('ignores invalid event format', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        final initialValue = controller.value;
        
        // Send non-map event
        eventStreamController.add('invalid event');

        await Future.delayed(const Duration(milliseconds: 100));

        // Value should not change
        expect(controller.value.state, initialValue.state);
      });

      test('handles initialized event with missing data', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'initialized',
          'data': {},
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.duration, Duration.zero);
        expect(controller.value.width, null);
        expect(controller.value.height, null);
      });

      test('handles position event with missing data', () async {
        await controller.initialize('https://example.com/video.mp4');
        
        eventStreamController.add({
          'event': 'position',
          'data': {},
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller.value.position, Duration.zero);
        expect(controller.value.bufferedPosition, Duration.zero);
      });
    });

  });
}
