import 'package:flutter_test/flutter_test.dart';
import 'package:native_core_video_player/native_core_video_player.dart';
import 'package:native_core_video_player/native_core_video_player_platform_interface.dart';
import 'package:native_core_video_player/native_core_video_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeCoreVideoPlayerPlatform
    with MockPlatformInterfaceMixin
    implements NativeCoreVideoPlayerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeCoreVideoPlayerPlatform initialPlatform = NativeCoreVideoPlayerPlatform.instance;

  test('$MethodChannelNativeCoreVideoPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeCoreVideoPlayer>());
  });

  test('getPlatformVersion', () async {
    NativeCoreVideoPlayer nativeCoreVideoPlayerPlugin = NativeCoreVideoPlayer();
    MockNativeCoreVideoPlayerPlatform fakePlatform = MockNativeCoreVideoPlayerPlatform();
    NativeCoreVideoPlayerPlatform.instance = fakePlatform;

    expect(await nativeCoreVideoPlayerPlugin.getPlatformVersion(), '42');
  });
}
