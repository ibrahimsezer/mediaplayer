import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:mediaplayer/media_player_controller.dart';
import 'package:mediaplayer/playlist.dart';
import 'package:mediaplayer/slide_page_action.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MediaPlayerViewModel extends ChangeNotifier {
  List<AudioSource> _songs = [];
  get songs => _songs;

  int _currentIndex = 0;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  late AudioPlayer _audioPlayer;
  get audioPlayer => _audioPlayer;

  Future<void> _loadLocalSongs() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (files != null) {
        _songs = files.paths.map((path) => AudioSource.file(path!)).toList();
        await _audioPlayer
            .setAudioSource(ConcatenatingAudioSource(children: _songs));
      }
    }
  }
}

class MediaPlayerView extends StatefulWidget {
  const MediaPlayerView({super.key});

  @override
  State<MediaPlayerView> createState() => _MediaPlayerViewState();
}

class _MediaPlayerViewState extends State<MediaPlayerView> {
  MediaPlayerViewModel get _mediaPlayer =>
      Provider.of<MediaPlayerViewModel>(context, listen: false);
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _mediaPlayer._audioPlayer.positionStream,
        _mediaPlayer._audioPlayer.bufferedPositionStream,
        _mediaPlayer._audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _mediaPlayer._audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _mediaPlayer._audioPlayer.setLoopMode(LoopMode.all);
    await _mediaPlayer._audioPlayer.setAudioSource(_mediaPlayer._songs.first);
  }

  @override
  void dispose() {
    _mediaPlayer._audioPlayer.dispose();
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
                        onSeek: _mediaPlayer._audioPlayer.seek,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Controls(audioPlayer: _mediaPlayer._audioPlayer),
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
