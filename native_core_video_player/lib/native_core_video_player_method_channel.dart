import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_core_video_player_platform_interface.dart';

/// An implementation of [NativeCoreVideoPlayerPlatform] that uses method channels.
class MethodChannelNativeCoreVideoPlayer extends NativeCoreVideoPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_core_video_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
