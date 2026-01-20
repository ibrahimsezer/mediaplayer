import 'package:flutter/material.dart';
import 'package:mediaplayer/helper/format_helper.dart';
import 'package:mediaplayer/model/song_model.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          song.albumArt,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        song.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
          color: isPlaying ? theme.colorScheme.primary : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isPlaying
              ? theme.colorScheme.primary.withValues(alpha: 0.7)
              : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            FormatHelper.formatDuration(song.duration),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Icon(
            isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
            color: isPlaying ? theme.colorScheme.primary : null,
          ),
        ],
      ),
    );
  }
}
