import 'package:flutter/material.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/view/widgets/playlist_card.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';

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
    final playlistViewModel = Provider.of<PlaylistViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      body: playlistViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistViewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(playlistViewModel.error),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          playlistViewModel.loadPlaylists();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Create playlist card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: InkWell(
                          onTap: () => _showCreatePlaylistDialog(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.64,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final playlist = playlistViewModel.playlists[index];
                            return PlaylistCard(
                              playlist: playlist,
                              onTap: () => onPlaylistSelected(playlist),
                              isHorizontal: false,
                            );
                          },
                          childCount: playlistViewModel.playlists.length,
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

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final playlistViewModel =
        Provider.of<PlaylistViewModel>(context, listen: false);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter playlist name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter playlist description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final playlist = await playlistViewModel.createPlaylist(
                  name,
                  description: descriptionController.text.trim(),
                );
                if (playlist != null) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
