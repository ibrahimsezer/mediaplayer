import 'package:flutter/material.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/view/widgets/playlist_card.dart';

class PlaylistsPage extends StatelessWidget {
  final Function(PlaylistModel) onPlaylistSelected;
  final VoidCallback onCreatePlaylistPressed;

  const PlaylistsPage({
    Key? key,
    required this.onPlaylistSelected,
    required this.onCreatePlaylistPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onCreatePlaylistPressed,
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Create playlist card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: onCreatePlaylistPressed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create New Playlist',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Playlists grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = PlaylistModel.mockPlaylists[index];
                  return PlaylistCard(
                    playlist: playlist,
                    onTap: () => onPlaylistSelected(playlist),
                    isHorizontal: false,
                  );
                },
                childCount: PlaylistModel.mockPlaylists.length,
              ),
            ),
          ),

          // Bottom padding for mini player
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}
