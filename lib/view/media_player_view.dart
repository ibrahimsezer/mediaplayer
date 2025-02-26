import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/const/const.dart';
import 'package:mediaplayer/view/media_player_control_widget.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:mediaplayer/view/playlist_view.dart';
import 'package:mediaplayer/view/settings_view.dart';
import 'package:mediaplayer/helper/slide_page_action.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPlayerView extends StatefulWidget {
  const MediaPlayerView({super.key});

  @override
  State<MediaPlayerView> createState() => _MediaPlayerViewState();
}

class _MediaPlayerViewState extends State<MediaPlayerView>
    with SingleTickerProviderStateMixin {
  late MediaPlayerViewModel _mediaPlayerViewModel;
  late AnimationController _visualizerController;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _showQueue = false;

  @override
  void initState() {
    super.initState();
    _mediaPlayerViewModel =
        Provider.of<MediaPlayerViewModel>(context, listen: false);
    _visualizerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _requestPermissions();
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _mediaPlayerViewModel.audioPlayer.positionStream,
        _mediaPlayerViewModel.audioPlayer.bufferedPositionStream,
        _mediaPlayerViewModel.audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  Future<void> _requestPermissions() async {
    try {
      if (await _checkAndRequestPermission()) {
        debugPrint("Storage Permission Granted");
        await _mediaPlayerViewModel.loadLocalSongs;
        await _init();
      } else {
        debugPrint("Storage Permission Denied");
      }
    } catch (e) {
      debugPrint("Failed to get permissions: $e");
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    if (await Permission.storage.status.isGranted) {
      return true;
    }

    if (await Permission.mediaLibrary.status.isGranted) {
      return true;
    }

    PermissionStatus status;
    if (await Permission.mediaLibrary.status.isPermanentlyDenied) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.mediaLibrary.request();
    }

    return status.isGranted;
  }

  Future<void> _init() async {
    await _mediaPlayerViewModel.audioPlayer.setLoopMode(LoopMode.all);
    await _mediaPlayerViewModel.audioPlayer
        .setAudioSource(_mediaPlayerViewModel.songs.first);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (_mediaPlayerViewModel.songs.isEmpty) return;
        if (details.primaryVelocity! > 0) {
          _mediaPlayerViewModel.audioPlayer.seekToPrevious();
        } else if (details.primaryVelocity! < 0) {
          _mediaPlayerViewModel.audioPlayer.seekToNext();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<MediaPlayerViewModel>(
            builder: (context, mediaPlayer, _) {
              final bool hasNoSongs = mediaPlayer.songs.isEmpty;

              if (hasNoSongs) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your playlist is empty',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add some songs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await mediaPlayer.loadLocalSongs();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Somethings goes wrongs: $e')),
                            );
                          }
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add Songs'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTopBar(),
                    SizedBox(height: 24),
                    _buildNowPlayingTitle(),
                    SizedBox(height: 32),
                    _buildAlbumArt(),
                    SizedBox(height: 24),
                    _buildProgressBar(),
                    SizedBox(height: 16),
                    _buildPlaybackControls(),
                    SizedBox(height: 24),
                    _buildVolumeControl(),
                    if (_showQueue) _buildQueuePeek(),
                    SlidePageAction(pageName: PlaylistView()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, mediaPlayer, _) {
        final bool hasNoSongs = mediaPlayer.songs.isEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text(
              ConstTexts.jswMediaPlayer,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsView()),
                    );
                  },
                ),
                IconButton(
                  icon:
                      Icon(_showQueue ? Icons.queue_music : Icons.playlist_add),
                  onPressed: hasNoSongs
                      ? null
                      : () => setState(() => _showQueue = !_showQueue),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNowPlayingTitle() {
    return StreamBuilder<SequenceState?>(
      stream: _mediaPlayerViewModel.audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state?.sequence.isEmpty ?? true) return SizedBox();

        final metadata = state?.currentSource;
        return Column(
          children: [
            Text(
              'Now Playing',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),
            Text(
              'Song ${_mediaPlayerViewModel.currentIndex + 1}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumArt() {
    return Hero(
      tag: 'album_art',
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image(
            image: AssetImage(AssetNames.defaultMusicLogo),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, mediaPlayer, _) {
        final bool hasNoSongs = mediaPlayer.songs.isEmpty;

        return StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return ProgressBar(
              progress: positionData?.position ?? Duration.zero,
              buffered: positionData?.bufferedPosition ?? Duration.zero,
              total: positionData?.duration ?? Duration.zero,
              onSeek: hasNoSongs ? null : mediaPlayer.audioPlayer.seek,
              barHeight: 4,
              baseBarColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              progressBarColor: Theme.of(context).colorScheme.primary,
              bufferedBarColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              thumbColor: hasNoSongs
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
              timeLabelTextStyle: Theme.of(context).textTheme.bodySmall,
            );
          },
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, mediaPlayer, _) {
        final bool hasNoSongs = mediaPlayer.songs.isEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                mediaPlayer.isShuffleMode
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
              ),
              onPressed: hasNoSongs ? null : mediaPlayer.toggleShuffleMode,
              color: hasNoSongs ? Colors.grey : null,
            ),
            SizedBox(width: 16),
            MediaPlayerControlWidget(
              audioPlayer: mediaPlayer.audioPlayer,
              isEnabled: !hasNoSongs,
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(
                mediaPlayer.isRepeatMode ? Icons.repeat_one : Icons.repeat,
              ),
              onPressed: hasNoSongs ? null : mediaPlayer.toggleRepeatMode,
              color: hasNoSongs ? Colors.grey : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeControl() {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, mediaPlayer, _) {
        final bool hasNoSongs = mediaPlayer.songs.isEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_down,
                size: 20, color: hasNoSongs ? Colors.grey : null),
            Expanded(
              child: Slider(
                value: _volume,
                onChanged: hasNoSongs
                    ? null
                    : (value) {
                        setState(() {
                          _volume = value;
                          mediaPlayer.audioPlayer.setVolume(value);
                        });
                      },
              ),
            ),
            Icon(Icons.volume_up,
                size: 20, color: hasNoSongs ? Colors.grey : null),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackSpeedControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed, size: 20),
        SizedBox(width: 8),
        DropdownButton<double>(
          value: _playbackSpeed,
          items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return DropdownMenuItem(
              value: speed,
              child: Text('${speed}x'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _playbackSpeed = value!;
              _mediaPlayerViewModel.audioPlayer.setSpeed(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildQueuePeek() {
    return Container(
      height: 120,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<SequenceState?>(
        stream: _mediaPlayerViewModel.audioPlayer.sequenceStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state?.sequence.isEmpty ?? true) {
            return Center(child: Text('Queue is empty'));
          }

          return ListView.builder(
            itemCount: state!.sequence.length,
            itemBuilder: (context, index) {
              final isPlaying = index == _mediaPlayerViewModel.currentIndex;
              return ListTile(
                dense: true,
                leading: Icon(
                  isPlaying ? Icons.play_arrow : Icons.music_note,
                  color:
                      isPlaying ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  'Song ${index + 1}',
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () => _playSong(index),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _playSong(int index) async {
    await _mediaPlayerViewModel.audioPlayer.seek(Duration.zero, index: index);
    _mediaPlayerViewModel.audioPlayer.play();
    _mediaPlayerViewModel.currentIndex = index;
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
