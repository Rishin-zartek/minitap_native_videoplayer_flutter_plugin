import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_core_video_player/native_core_video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Video Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VideoListScreen(),
    );
  }
}

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  static const List<VideoItem> videos = [
    VideoItem(
      title: 'Big Buck Bunny (MP4)',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      description: 'Standard MP4 video test',
    ),
    VideoItem(
      title: 'Elephant Dream (MP4)',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      description: 'Another MP4 video test',
    ),
    VideoItem(
      title: 'HLS Stream Test',
      url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      description: 'HLS adaptive streaming test',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Video Player Demo'),
        elevation: 2,
      ),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline, size: 40),
              title: Text(video.title),
              subtitle: Text(video.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class VideoItem {
  final String title;
  final String url;
  final String description;

  const VideoItem({
    required this.title,
    required this.url,
    required this.description,
  });
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late NativeVideoController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = NativeVideoController();
    
    try {
      await _controller.initialize(widget.video.url);
      setState(() {
        _isLoading = false;
      });
      await _controller.play();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : VideoPlayerWithControls(controller: _controller),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _ControlPanel(controller: _controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatefulWidget {
  final NativeVideoController controller;

  const _ControlPanel({required this.controller});

  @override
  State<_ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<_ControlPanel> {
  double _volume = 1.0;
  double _speed = 1.0;
  bool _isLooping = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.controller.play(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.controller.pause(),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Volume', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Icon(Icons.volume_down),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume * 100).round()}%',
                onChanged: (value) {
                  setState(() => _volume = value);
                  widget.controller.setVolume(value);
                },
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Playback Speed', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('0.5x'),
            Expanded(
              child: Slider(
                value: _speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${_speed.toStringAsFixed(1)}x',
                onChanged: (value) {
                  setState(() => _speed = value);
                  widget.controller.setPlaybackSpeed(value);
                },
              ),
            ),
            const Text('2.0x'),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Loop Video'),
          value: _isLooping,
          onChanged: (value) {
            setState(() => _isLooping = value);
            widget.controller.setLooping(value);
          },
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: widget.controller,
          builder: (context, value, child) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Info',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('State: ${value.state.name}'),
                    Text('Duration: ${_formatDuration(value.duration)}'),
                    Text('Position: ${_formatDuration(value.position)}'),
                    if (value.width != null && value.height != null)
                      Text('Resolution: ${value.width}x${value.height}'),
                    Text('Volume: ${(_volume * 100).round()}%'),
                    Text('Speed: ${_speed.toStringAsFixed(1)}x'),
                    Text('Looping: ${_isLooping ? "Yes" : "No"}'),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
