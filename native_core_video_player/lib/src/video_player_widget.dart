import 'package:flutter/material.dart';
import 'video_controller.dart';
import 'video_state.dart';

class VideoPlayerWidget extends StatelessWidget {
  final NativeVideoController controller;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.hasError) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      value.errorMessage ?? 'An error occurred',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        if (!value.isInitialized || controller.textureId == null) {
          return placeholder ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        final textureId = controller.textureId!;
        final width = value.width?.toDouble() ?? 16.0;
        final height = value.height?.toDouble() ?? 9.0;
        final aspectRatio = width / height;

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Texture(textureId: textureId),
          ),
        );
      },
    );
  }
}

class VideoPlayerWithControls extends StatefulWidget {
  final NativeVideoController controller;
  final bool showControls;

  const VideoPlayerWithControls({
    super.key,
    required this.controller,
    this.showControls = true,
  });

  @override
  State<VideoPlayerWithControls> createState() => _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.showControls) {
          setState(() {
            _showControls = !_showControls;
          });
        }
      },
      child: Stack(
        children: [
          VideoPlayerWidget(controller: widget.controller),
          if (widget.showControls && _showControls)
            Positioned.fill(
              child: _VideoControls(controller: widget.controller),
            ),
        ],
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final NativeVideoController controller;

  const _VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(value.position),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            value: value.duration.inMilliseconds > 0
                                ? value.position.inMilliseconds /
                                    value.duration.inMilliseconds
                                : 0.0,
                            onChanged: (newValue) {
                              final position = Duration(
                                milliseconds:
                                    (newValue * value.duration.inMilliseconds).toInt(),
                              );
                              controller.seekTo(position);
                            },
                          ),
                        ),
                        Text(
                          _formatDuration(value.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = value.position - const Duration(seconds: 10);
                          controller.seekTo(
                            newPosition < Duration.zero ? Duration.zero : newPosition,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          if (value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          final newPosition = value.position + const Duration(seconds: 10);
                          controller.seekTo(
                            newPosition > value.duration
                                ? value.duration
                                : newPosition,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
