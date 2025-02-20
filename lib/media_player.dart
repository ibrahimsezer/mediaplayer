import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:mediaplayer/media_player_controller.dart';
import 'package:mediaplayer/playlist.dart';
import 'package:mediaplayer/slide_page_action.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MediaPlayer extends StatefulWidget {
  const MediaPlayer({super.key});

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  late AudioPlayer _audioPlayer;
  final _playlist = ConcatenatingAudioSource(children: [
    AudioSource.uri(
      Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
      tag: 'Song 1',
    ),
  ]);

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode),
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),
              SizedBox(
                height: 48,
              ),
              Text(
                "JSW Media Player",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              SizedBox(
                height: 48,
              ),
              Column(
                children: [
                  CircleAvatar(
                      radius: 100,
                      foregroundImage: AssetImage(
                          'lib/assets/images/default_music_photo.png')),
                  const SizedBox(height: 50),
                  StreamBuilder<PositionData>(
                    stream: _positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      return ProgressBar(
                        progress: positionData?.position ?? Duration.zero,
                        buffered:
                            positionData?.bufferedPosition ?? Duration.zero,
                        total: positionData?.duration ?? Duration.zero,
                        onSeek: _audioPlayer.seek,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Controls(audioPlayer: _audioPlayer),
              Spacer(),
              SlidePageAction(
                pageName: Playlist(),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}
