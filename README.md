# 🚀 Native High-Performance Video Player Plugin for Flutter

A **high-performance**, **fully customizable**, and **zero third-party dependency** native video player plugin built using **only Flutter core + platform-native APIs**.

This plugin directly integrates:

* **Android** → `ExoPlayer` (Media3 - native Android SDK)
* **iOS** → `AVPlayer` (Apple AVFoundation)
* **Flutter** → `Platform Channels + Texture rendering`

**No external pub.dev packages. No wrappers. Fully native performance.**

---

## 🎯 Objective

Build a **production-grade video player plugin** that:

* Uses **only Flutter SDK + native platform APIs**
* Provides **maximum rendering performance** via Texture rendering
* Supports **custom UI controls**
* Allows **fine-grained configuration**
* Works smoothly for large-scale apps
* Is scalable and maintainable

---

## 🏗 Architecture Overview

```
Flutter UI
   ↓
Platform Channel (MethodChannel + EventChannel)
   ↓
Native Video Engine
   → Android: ExoPlayer (Media3)
   → iOS: AVPlayer
   ↓
Texture Rendering (60fps)
```

---

## 🔥 Core Principles

* ✅ No third-party dependencies (only Flutter SDK)
* ✅ Use Texture instead of PlatformView (better performance)
* ✅ Lifecycle-aware playback (pause on background, resume on foreground)
* ✅ Memory efficient (proper resource cleanup)
* ✅ Low-latency seeking
* ✅ Background/foreground handling
* ✅ Full native control exposure

---

## 📦 Features

### 🎬 Playback

* ✅ Network video (HTTP/HTTPS)
* ✅ Local file video
* ✅ Asset video
* ✅ HLS streaming (.m3u8)
* ✅ MP4, WebM, and other formats
* ✅ Looping
* ✅ Auto-play
* ✅ Playback speed control (0.5x - 2.0x)

### 🎛 Controls

* ✅ Play / Pause
* ✅ Seek to position
* ✅ Forward / Rewind (10 seconds)
* ✅ Volume control (0.0 - 1.0)
* ✅ Mute / Unmute
* ✅ Custom overlay support

### 📊 State & Callbacks

* ✅ Buffering state
* ✅ Playing state
* ✅ Paused state
* ✅ Completed state
* ✅ Error handling
* ✅ Current position stream (100ms updates)
* ✅ Duration stream
* ✅ Buffered position tracking

### 🎨 Customization

* ✅ Fully custom Flutter UI
* ✅ Custom control overlay
* ✅ Custom progress bar
* ✅ Gesture controls
* ✅ Theming support

---

## 📂 Project Structure

```
native_core_video_player/
│
├── lib/
│   ├── native_core_video_player.dart          # Main export file
│   └── src/
│       ├── video_controller.dart              # Controller with MethodChannel/EventChannel
│       ├── video_player_widget.dart           # Texture-based video widget
│       └── video_state.dart                   # State models
│
├── android/
│   └── src/main/kotlin/com/example/native_core_video_player/
│       ├── NativeCoreVideoPlayerPlugin.kt     # Android plugin entry
│       └── VideoPlayer.kt                     # ExoPlayer implementation
│
├── ios/
│   └── Classes/
│       ├── NativeCoreVideoPlayerPlugin.swift  # iOS plugin entry
│       └── VideoPlayer.swift                  # AVPlayer implementation
│
├── example/                                    # Example app with demo
└── apk-builds/                                 # Release APK builds
```

---

## 🚀 Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  native_core_video_player:
    path: ../native_core_video_player
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:native_core_video_player/native_core_video_player.dart';

class VideoPlayerExample extends StatefulWidget {
  @override
  State<VideoPlayerExample> createState() => _VideoPlayerExampleState();
}

class _VideoPlayerExampleState extends State<VideoPlayerExample> {
  late NativeVideoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NativeVideoController();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _controller.initialize(
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    );
    await _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWithControls(controller: _controller),
        ),
      ),
    );
  }
}
```

### Advanced Usage with Custom Controls

```dart
// Simple video player without controls
VideoPlayerWidget(controller: _controller)

// Video player with built-in controls
VideoPlayerWithControls(controller: _controller)

// Control playback
await _controller.play();
await _controller.pause();
await _controller.seekTo(Duration(seconds: 30));
await _controller.setVolume(0.5);
await _controller.setPlaybackSpeed(1.5);
await _controller.setLooping(true);

// Listen to state changes
ValueListenableBuilder<VideoPlayerValue>(
  valueListenable: _controller,
  builder: (context, value, child) {
    return Text('State: ${value.state.name}');
  },
)
```

---

## ⚙️ Performance Optimizations

* ✅ **TextureRegistry** instead of PlatformViews for 60fps rendering
* ✅ **Pre-buffering** video before playback
* ✅ **Proper resource cleanup** on dispose
* ✅ **HandlerThread** (Android) for background operations
* ✅ **Efficient AVPlayer observation** (iOS)
* ✅ **Minimal channel communication** overhead
* ✅ **SurfaceProducer API** (Android) for modern texture handling

---

## 🧪 Testing Strategy

The plugin has been tested with:

* ✅ Large video files (1GB+)
* ✅ HLS adaptive streaming
* ✅ Rapid seek operations
* ✅ Background/foreground transitions
* ✅ Device rotation
* ✅ Memory leak profiling

---

## 📱 Example App

The example app demonstrates:

* Multiple video sources (MP4, HLS)
* Custom controls (play/pause, seek, volume, speed)
* Real-time video info display
* Looping functionality
* State management

### Running the Example

```bash
cd native_core_video_player/example
flutter run
```

### Building APK

```bash
cd native_core_video_player/example
flutter build apk --release
```

Pre-built APK available in: `apk-builds/native_video_player_v0.0.1.apk`

---

## 🔧 Technical Implementation

### Android (ExoPlayer)

* Uses **Media3 ExoPlayer** (androidx.media3:media3-exoplayer:1.5.0)
* **SurfaceProducer** for texture rendering
* **ActivityAware** for lifecycle management
* **HandlerThread** for background operations
* Automatic pause on background, resume on foreground

### iOS (AVPlayer)

* Uses **AVFoundation AVPlayer**
* **AVPlayerItemVideoOutput** for texture rendering
* **FlutterTexture** protocol implementation
* **CADisplayLink** for smooth frame updates
* **KVO observers** for status tracking
* **Notification observers** for lifecycle events

### Flutter (Dart)

* **MethodChannel** for commands (play, pause, seek, etc.)
* **EventChannel** for continuous streams (position, state, errors)
* **ValueNotifier** for reactive state management
* **Texture widget** for video rendering
* Proper disposal and cleanup

---

## 📌 Why This Approach?

* ✅ **Maximum performance** - Direct native integration
* ✅ **Zero dependency risk** - No third-party packages
* ✅ **Full native flexibility** - Complete control over player
* ✅ **Enterprise ready** - Production-grade implementation
* ✅ **Large-scale app compatibility** - Optimized for performance

---

## 🚀 Future Enhancements

Potential features for future versions:

* DRM support (Widevine, FairPlay)
* Offline caching
* Subtitles (WebVTT, SRT)
* Audio track selection
* Advanced buffering analytics
* Hardware acceleration toggle
* Picture-in-Picture mode
* 360° video support

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📧 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

## 🎉 Acknowledgments

Built with ❤️ using:
- Flutter SDK
- Android ExoPlayer (Media3)
- iOS AVPlayer (AVFoundation)

---

**Made with Flutter 🚀**
