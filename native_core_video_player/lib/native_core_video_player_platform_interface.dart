import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_core_video_player_method_channel.dart';

abstract class NativeCoreVideoPlayerPlatform extends PlatformInterface {
  /// Constructs a NativeCoreVideoPlayerPlatform.
  NativeCoreVideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeCoreVideoPlayerPlatform _instance = MethodChannelNativeCoreVideoPlayer();

  /// The default instance of [NativeCoreVideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeCoreVideoPlayer].
  static NativeCoreVideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeCoreVideoPlayerPlatform] when
  /// they register themselves.
  static set instance(NativeCoreVideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
