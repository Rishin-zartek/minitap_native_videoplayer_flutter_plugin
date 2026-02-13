import 'package:flutter_test/flutter_test.dart';
import 'package:native_core_video_player/src/video_state.dart';

void main() {
  group('VideoPlayerValue', () {
    test('creates with default values', () {
      const value = VideoPlayerValue();
      
      expect(value.state, VideoState.idle);
      expect(value.position, Duration.zero);
      expect(value.duration, Duration.zero);
      expect(value.bufferedPosition, Duration.zero);
      expect(value.volume, 1.0);
      expect(value.playbackSpeed, 1.0);
      expect(value.isLooping, false);
      expect(value.width, null);
      expect(value.height, null);
      expect(value.errorCode, null);
      expect(value.errorMessage, null);
    });

    test('creates with custom values', () {
      const value = VideoPlayerValue(
        state: VideoState.playing,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 60),
        bufferedPosition: Duration(seconds: 20),
        volume: 0.5,
        playbackSpeed: 1.5,
        isLooping: true,
        width: 1920,
        height: 1080,
        errorCode: 'test_error',
        errorMessage: 'Test error message',
      );
      
      expect(value.state, VideoState.playing);
      expect(value.position, const Duration(seconds: 10));
      expect(value.duration, const Duration(seconds: 60));
      expect(value.bufferedPosition, const Duration(seconds: 20));
      expect(value.volume, 0.5);
      expect(value.playbackSpeed, 1.5);
      expect(value.isLooping, true);
      expect(value.width, 1920);
      expect(value.height, 1080);
      expect(value.errorCode, 'test_error');
      expect(value.errorMessage, 'Test error message');
    });

    test('isInitialized returns false when duration is zero', () {
      const value = VideoPlayerValue();
      expect(value.isInitialized, false);
    });

    test('isInitialized returns true when duration is greater than zero', () {
      const value = VideoPlayerValue(duration: Duration(seconds: 60));
      expect(value.isInitialized, true);
    });

    test('isPlaying returns true when state is playing', () {
      const value = VideoPlayerValue(state: VideoState.playing);
      expect(value.isPlaying, true);
    });

    test('isPlaying returns false when state is not playing', () {
      const value = VideoPlayerValue(state: VideoState.paused);
      expect(value.isPlaying, false);
    });

    test('hasError returns true when state is error', () {
      const value = VideoPlayerValue(state: VideoState.error);
      expect(value.hasError, true);
    });

    test('hasError returns false when state is not error', () {
      const value = VideoPlayerValue(state: VideoState.playing);
      expect(value.hasError, false);
    });

    test('copyWith creates new instance with updated values', () {
      const original = VideoPlayerValue(
        state: VideoState.idle,
        position: Duration(seconds: 5),
        volume: 1.0,
      );
      
      final updated = original.copyWith(
        state: VideoState.playing,
        position: const Duration(seconds: 10),
      );
      
      expect(updated.state, VideoState.playing);
      expect(updated.position, const Duration(seconds: 10));
      expect(updated.volume, 1.0); // unchanged
    });

    test('copyWith preserves original values when null is passed', () {
      const original = VideoPlayerValue(
        state: VideoState.playing,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 60),
        volume: 0.8,
      );
      
      final updated = original.copyWith();
      
      expect(updated.state, original.state);
      expect(updated.position, original.position);
      expect(updated.duration, original.duration);
      expect(updated.volume, original.volume);
    });

    test('copyWith can update all fields', () {
      const original = VideoPlayerValue();
      
      final updated = original.copyWith(
        state: VideoState.playing,
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 60),
        bufferedPosition: const Duration(seconds: 20),
        volume: 0.5,
        playbackSpeed: 1.5,
        isLooping: true,
        width: 1920,
        height: 1080,
        errorCode: 'test_error',
        errorMessage: 'Test error message',
      );
      
      expect(updated.state, VideoState.playing);
      expect(updated.position, const Duration(seconds: 10));
      expect(updated.duration, const Duration(seconds: 60));
      expect(updated.bufferedPosition, const Duration(seconds: 20));
      expect(updated.volume, 0.5);
      expect(updated.playbackSpeed, 1.5);
      expect(updated.isLooping, true);
      expect(updated.width, 1920);
      expect(updated.height, 1080);
      expect(updated.errorCode, 'test_error');
      expect(updated.errorMessage, 'Test error message');
    });

    test('toString returns formatted string', () {
      const value = VideoPlayerValue(
        state: VideoState.playing,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 60),
      );
      
      final str = value.toString();
      expect(str, contains('VideoPlayerValue'));
      expect(str, contains('playing'));
      expect(str, contains('0:00:10'));
      expect(str, contains('0:01:00'));
    });
  });

  group('VideoState', () {
    test('has all expected states', () {
      expect(VideoState.values, contains(VideoState.idle));
      expect(VideoState.values, contains(VideoState.buffering));
      expect(VideoState.values, contains(VideoState.playing));
      expect(VideoState.values, contains(VideoState.paused));
      expect(VideoState.values, contains(VideoState.completed));
      expect(VideoState.values, contains(VideoState.error));
    });

    test('enum values are distinct', () {
      final states = VideoState.values.toSet();
      expect(states.length, VideoState.values.length);
    });
  });
}
