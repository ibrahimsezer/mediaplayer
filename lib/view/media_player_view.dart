import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/const/const.dart';
import 'package:mediaplayer/view/media_player_control_widget.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:mediaplayer/view/playlist_view.dart';
import 'package:mediaplayer/helper/slide_page_action.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

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
        _mediaPlayer.audioPlayer.positionStream,
        _mediaPlayer.audioPlayer.bufferedPositionStream,
        _mediaPlayer.audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  void initState() {
    super.initState();
    _mediaPlayer.audioPlayer;
    _mediaPlayer.loadLocalSongs;
    _init();
  }

  Future<void> _init() async {
    await _mediaPlayer.audioPlayer.setLoopMode(LoopMode.all);
    await _mediaPlayer.audioPlayer.setAudioSource(_mediaPlayer.songs.first);
  }

  @override
  void dispose() {
    _mediaPlayer.audioPlayer.dispose();
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
                ConstTexts.jswMediaPlayer,
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
                      foregroundImage: AssetImage(AssetNames.defaultMusicLogo)),
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
                        onSeek: _mediaPlayer.audioPlayer.seek,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MediaPlayerControlWidget(audioPlayer: _mediaPlayer.audioPlayer),
              Spacer(),
              SlidePageAction(
                pageName: PlaylistView(),
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
