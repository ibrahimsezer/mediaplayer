import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:mediaplayer/const/const.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:mediaplayer/view/media_player_control_widget.dart';
import 'package:mediaplayer/view/playlist_view.dart';
import 'package:mediaplayer/view/settings_view.dart';
import 'package:mediaplayer/viewmodel/music_player_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MusicPlayerView extends StatefulWidget {
  const MusicPlayerView({super.key});

  @override
  State<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends State<MusicPlayerView> {
  double _volume = 1.0;
  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<MusicPlayerViewModel>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
        centerTitle: true,
        title: Text(
          ConstTexts.jswMediaPlayer,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsView()),
              );
            },
          ),
        ],
      ),
      body:
          Consumer<MusicPlayerViewModel>(builder: (context, viewModel, child) {
        return Column(
          children: [
            if (viewModel.songs.isEmpty)
              Center(
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
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await viewModel.loadSongs();
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
              ),
            if (viewModel.currentSong != null || viewModel.songs.isNotEmpty)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlaylistView()),
                    ),
                    child: Text('Playlist'),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                    ],
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }

  late MusicPlayerViewModel viewModel;

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        viewModel.audioPlayer.positionStream,
        viewModel.audioPlayer.bufferedPositionStream,
        viewModel.audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  Widget _controlWid() {
    return Column(
      children: [
        Text(viewModel.currentSong!.title),
        Slider(
          value: viewModel.currentPosition.inSeconds.toDouble(),
          max: viewModel.totalDuration.inSeconds.toDouble(),
          onChanged: (value) {
            viewModel.seek(Duration(seconds: value.toInt()));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(viewModel.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (viewModel.isPlaying) {
                  viewModel.pause();
                } else {
                  viewModel.resume();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNowPlayingTitle() {
    return Consumer<MusicPlayerViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.songs.isEmpty) return SizedBox();

        return Column(
          children: [
            Text(
              'Now Playing',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),
            Text(
              viewModel.songs[viewModel.currentIndex].title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumArt() {
    return Consumer<MusicPlayerViewModel>(
      builder: (context, viewModel, _) {
        final hasNoSongs = viewModel.songs.isEmpty;
        final currentSong =
            hasNoSongs ? null : viewModel.songs[viewModel.currentIndex];

        return Hero(
          tag: 'album_art',
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: currentSong?.artworkUri != null
                  ? Image.file(
                      File(currentSong!.artworkUri!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          AssetNames.defaultMusicLogo,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      AssetNames.defaultMusicLogo,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Consumer<MusicPlayerViewModel>(
      builder: (context, viewModel, _) {
        final bool hasNoSongs = viewModel.songs.isEmpty;

        return StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return ProgressBar(
              progress: positionData?.position ?? Duration.zero,
              buffered: positionData?.bufferedPosition ?? Duration.zero,
              total: positionData?.duration ?? Duration.zero,
              onSeek: hasNoSongs ? null : viewModel.audioPlayer.seek,
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
    return Consumer<MusicPlayerViewModel>(
      builder: (context, viewModel, _) {
        final bool hasNoSongs = viewModel.songs.isEmpty;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                viewModel.isShuffleMode
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
              ),
              onPressed: hasNoSongs ? null : viewModel.toggleShuffleMode,
              color: hasNoSongs ? Colors.grey : null,
            ),
            SizedBox(width: 16),
            MediaPlayerControlWidget(
              audioPlayer: viewModel.audioPlayer,
              isEnabled: !hasNoSongs,
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(
                viewModel.isRepeatMode ? Icons.repeat_one : Icons.repeat,
              ),
              onPressed: hasNoSongs ? null : viewModel.toggleRepeatMode,
              color: hasNoSongs ? Colors.grey : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeControl() {
    return Consumer<MusicPlayerViewModel>(
      builder: (context, viewModel, _) {
        final bool hasNoSongs = viewModel.songs.isEmpty;
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
                          viewModel.audioPlayer.setVolume(value);
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
