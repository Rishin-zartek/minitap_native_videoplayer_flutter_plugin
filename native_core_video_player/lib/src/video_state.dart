enum VideoState {
  idle,
  buffering,
  playing,
  paused,
  completed,
  error,
}

class VideoPlayerValue {
  final VideoState state;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final double playbackSpeed;
  final bool isLooping;
  final int? width;
  final int? height;
  final String? errorCode;
  final String? errorMessage;

  const VideoPlayerValue({
    this.state = VideoState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isLooping = false,
    this.width,
    this.height,
    this.errorCode,
    this.errorMessage,
  });

  bool get isInitialized => duration > Duration.zero;
  bool get isPlaying => state == VideoState.playing;
  bool get hasError => state == VideoState.error;

  VideoPlayerValue copyWith({
    VideoState? state,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    double? playbackSpeed,
    bool? isLooping,
    int? width,
    int? height,
    String? errorCode,
    String? errorMessage,
  }) {
    return VideoPlayerValue(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLooping: isLooping ?? this.isLooping,
      width: width ?? this.width,
      height: height ?? this.height,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'VideoPlayerValue(state: $state, position: $position, duration: $duration)';
  }
}
