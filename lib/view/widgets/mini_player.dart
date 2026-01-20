import 'package:flutter/material.dart';
import 'package:mediaplayer/const/app_constants.dart';
import 'package:mediaplayer/model/song_model.dart';

class MiniPlayer extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art
            Hero(
              tag: 'album_art_${song.id}',
              child: SizedBox(
                height: 64,
                width: 64,
                child: Image.asset(
                  song.albumArt,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Song info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Song title with marquee effect
                    Text(
                      song.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Artist name
                    Text(
                      song.artist,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Play/Pause button
            IconButton(
              onPressed: onPlayPause,
              icon: AnimatedSwitcher(
                duration: AppConstants.quickAnimationDuration,
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  key: ValueKey<bool>(isPlaying),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // Next button
            IconButton(
              onPressed: onNext,
              icon: Icon(
                Icons.skip_next,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
