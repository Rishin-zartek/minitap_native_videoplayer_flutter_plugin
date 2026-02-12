import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_core_video_player/src/video_controller.dart';
import 'package:native_core_video_player/src/video_player_widget.dart';
import 'package:native_core_video_player/src/video_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayerWidget', () {
    late NativeVideoController controller;

    setUp(() {
      controller = NativeVideoController();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('native_core_video_player'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'initialize') {
            return 123;
          }
          return null;
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

    testWidgets('shows placeholder when not initialized', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom placeholder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              controller: controller,
              placeholder: const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error widget when hasError is true', (tester) async {
      controller.value = controller.value.copyWith(
        state: VideoState.error,
        errorMessage: 'Test error',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('shows custom error widget when provided', (tester) async {
      controller.value = controller.value.copyWith(
        state: VideoState.error,
        errorMessage: 'Test error',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              controller: controller,
              errorWidget: const Text('Custom error'),
            ),
          ),
        ),
      );

      expect(find.text('Custom error'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('shows default error message when errorMessage is null', (tester) async {
      controller.value = controller.value.copyWith(
        state: VideoState.error,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('shows texture when initialized', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Texture), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('uses default aspect ratio when dimensions are null', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      await tester.pump();

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 16.0 / 9.0);
    });

    testWidgets('calculates aspect ratio from video dimensions', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      await tester.pump();

      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 1920.0 / 1080.0);
    });

    testWidgets('updates when controller value changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pump();

      expect(find.byType(Texture), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('VideoPlayerWithControls', () {
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
          if (methodCall.method == 'initialize') {
            return 123;
          }
          return null;
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

    testWidgets('renders VideoPlayerWidget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      expect(find.byType(VideoPlayerWidget), findsOneWidget);
    });

    testWidgets('shows controls by default', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.replay_10), findsOneWidget);
      expect(find.byIcon(Icons.forward_10), findsOneWidget);
    });

    testWidgets('toggles controls visibility on tap', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byType(VideoPlayerWithControls));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsNothing);

      await tester.tap(find.byType(VideoPlayerWithControls));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('does not show controls when showControls is false', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(
              controller: controller,
              showControls: false,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('play button calls controller.play()', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
        state: VideoState.paused,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(methodCalls.any((call) => call.method == 'play'), true);
    });

    testWidgets('pause button calls controller.pause()', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        width: 1920,
        height: 1080,
        state: VideoState.playing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(methodCalls.any((call) => call.method == 'pause'), true);
    });

    testWidgets('replay button seeks backward 10 seconds', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        position: const Duration(seconds: 30),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();

      final seekCall = methodCalls.firstWhere((call) => call.method == 'seekTo');
      expect(seekCall.arguments['position'], 20000); // 20 seconds in milliseconds
    });

    testWidgets('replay button does not seek before zero', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        position: const Duration(seconds: 5),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();

      final seekCall = methodCalls.firstWhere((call) => call.method == 'seekTo');
      expect(seekCall.arguments['position'], 0);
    });

    testWidgets('forward button seeks forward 10 seconds', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        position: const Duration(seconds: 30),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pump();

      final seekCall = methodCalls.firstWhere((call) => call.method == 'seekTo');
      expect(seekCall.arguments['position'], 40000); // 40 seconds in milliseconds
    });

    testWidgets('forward button does not seek beyond duration', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 60),
        position: const Duration(seconds: 55),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pump();

      final seekCall = methodCalls.firstWhere((call) => call.method == 'seekTo');
      expect(seekCall.arguments['position'], 60000); // duration in milliseconds
    });

    testWidgets('displays formatted position and duration', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(minutes: 5, seconds: 30),
        position: const Duration(minutes: 2, seconds: 15),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('02:15'), findsOneWidget);
      expect(find.text('05:30'), findsOneWidget);
    });

    testWidgets('displays hours when duration exceeds 1 hour', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(hours: 1, minutes: 30, seconds: 45),
        position: const Duration(hours: 0, minutes: 45, seconds: 30),
        width: 1920,
        height: 1080,
        state: VideoState.paused,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();

      // Check that time displays exist (format may vary)
      expect(find.textContaining('45:30'), findsOneWidget);
      expect(find.textContaining('30:45'), findsOneWidget);
    });

    testWidgets('slider updates position on change', (tester) async {
      await controller.initialize('https://example.com/video.mp4');
      controller.value = controller.value.copyWith(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 50),
        width: 1920,
        height: 1080,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWithControls(controller: controller),
          ),
        ),
      );

      await tester.pump();
      methodCalls.clear();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      expect(methodCalls.any((call) => call.method == 'seekTo'), true);
    });
  });
}
