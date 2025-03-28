import 'package:flutter/material.dart';
import 'package:mediaplayer/const/app_constants.dart';
import 'package:mediaplayer/helper/format_helper.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:just_audio/just_audio.dart';

class NowPlayingPage extends StatefulWidget {
  final SongModel song;
  final bool isPlaying;
  final Function(bool) onPlayPausePressed;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onShuffleToggled;
  final VoidCallback onRepeatToggled;

  const NowPlayingPage({
    Key? key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.onShuffleToggled,
    required this.onRepeatToggled,
  }) : super(key: key);

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Album Art
          Hero(
            tag: 'album_art_${widget.song.id}',
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: widget.isPlaying
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * 3.14159,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          widget.song.albumArt,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        widget.song.albumArt,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Song Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Text(
                  widget.song.title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.song.artist,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.textTheme.titleSmall?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.song.album,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ProgressBar(
              progress: audioPlayerViewModel.position,
              buffered: audioPlayerViewModel.bufferedPosition,
              total: audioPlayerViewModel.duration,
              progressBarColor: theme.colorScheme.primary,
              baseBarColor: theme.colorScheme.primary.withOpacity(0.2),
              bufferedBarColor: theme.colorScheme.primary.withOpacity(0.5),
              thumbColor: theme.colorScheme.primary,
              barHeight: 4.0,
              thumbRadius: 7.0,
              timeLabelTextStyle: theme.textTheme.bodySmall,
              timeLabelPadding: 8.0,
              onSeek: (duration) {
                audioPlayerViewModel.seek(duration);
              },
            ),
          ),

          const Spacer(flex: 1),

          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shuffle button
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: audioPlayerViewModel.shuffleModeEnabled
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color?.withOpacity(0.7),
                ),
                onPressed: widget.onShuffleToggled,
                iconSize: 28,
              ),

              const SizedBox(width: 12),

              // Previous button
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: widget.onPreviousPressed,
                iconSize: 42,
              ),

              const SizedBox(width: 12),

              // Play/Pause button
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: AppConstants.quickAnimationDuration,
                    child: Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      key: ValueKey<bool>(widget.isPlaying),
                      color: theme.colorScheme.primary,
                      size: 42,
                    ),
                  ),
                  onPressed: () => widget.onPlayPausePressed(!widget.isPlaying),
                  iconSize: 42,
                ),
              ),

              const SizedBox(width: 12),

              // Next button
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: widget.onNextPressed,
                iconSize: 42,
              ),

              const SizedBox(width: 12),

              // Repeat button
              IconButton(
                icon: Icon(
                  _getRepeatIcon(audioPlayerViewModel.loopMode),
                  color: audioPlayerViewModel.loopMode != LoopMode.off
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color?.withOpacity(0.7),
                ),
                onPressed: widget.onRepeatToggled,
                iconSize: 28,
              ),
            ],
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.all:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      default:
        return Icons.repeat;
    }
  }
}
