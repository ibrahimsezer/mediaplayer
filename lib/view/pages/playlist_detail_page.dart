import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/song_tile.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';
import 'package:mediaplayer/viewmodel/library_viewmodel.dart';

class PlaylistDetailPage extends StatefulWidget {
  final PlaylistModel playlist;
  final Function(SongModel) onSongSelected;

  const PlaylistDetailPage({
    Key? key,
    required this.playlist,
    required this.onSongSelected,
  }) : super(key: key);

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  @override
  void initState() {
    super.initState();
    // Select the playlist in the viewmodel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlistViewModel =
          Provider.of<PlaylistViewModel>(context, listen: false);
      playlistViewModel.selectPlaylist(widget.playlist.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);
    final playlistViewModel = Provider.of<PlaylistViewModel>(context);

    // Get the current playlist
    final currentPlaylist =
        playlistViewModel.selectedPlaylist ?? widget.playlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditPlaylistDialog(context, currentPlaylist),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeletePlaylist(context, currentPlaylist),
          ),
        ],
      ),
      body: Column(
        children: [
          // Playlist header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                // Playlist cover art
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: currentPlaylist.coverArt.isNotEmpty
                      ? Image.asset(
                          currentPlaylist.coverArt,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.queue_music,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                ),

                const SizedBox(width: 16),

                // Playlist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPlaylist.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (currentPlaylist.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentPlaylist.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${currentPlaylist.songs.length} songs',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                            onPressed: currentPlaylist.songs.isEmpty
                                ? null
                                : () {
                                    try {
                                      // Load the playlist songs directly without making a copy
                                      audioPlayerViewModel
                                          .loadPlaylist(currentPlaylist.songs)
                                          .then((_) {
                                        // After loading is complete, tell the parent about the first song
                                        if (currentPlaylist.songs.isNotEmpty) {
                                          // This will trigger the mini player to appear
                                          widget.onSongSelected(
                                              currentPlaylist.songs.first);
                                        }
                                      }).catchError((e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error starting playback: $e'),
                                          ),
                                        );
                                      });
                                    } catch (e) {
                                      log('Error playing playlist: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to play playlist: ${e.toString()}'),
                                        ),
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddSongsDialog(context),
                            tooltip: 'Add Songs',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Songs list
          Expanded(
            child: currentPlaylist.songs.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    itemCount: currentPlaylist.songs.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      playlistViewModel.reorderSongsInSelectedPlaylist(
                          oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = currentPlaylist.songs[index];
                      return Dismissible(
                        key: Key('song_${song.id}_$index'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          playlistViewModel
                              .removeSongFromSelectedPlaylist(song.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${song.title} removed from playlist'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  playlistViewModel
                                      .addSongToSelectedPlaylist(song);
                                },
                              ),
                            ),
                          );
                        },
                        child: SongTile(
                          song: song,
                          isPlaying:
                              audioPlayerViewModel.currentSong?.id == song.id &&
                                  audioPlayerViewModel.isPlaying,
                          onTap: () {
                            try {
                              widget.onSongSelected(song);
                              audioPlayerViewModel.playSong(song);
                            } catch (e) {
                              log('Error playing song: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to play song: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit playlist details
  void _showEditPlaylistDialog(BuildContext context, PlaylistModel playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter playlist name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
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
            onPressed: () {
              final playlistViewModel =
                  Provider.of<PlaylistViewModel>(context, listen: false);
              playlistViewModel.updatePlaylist(
                playlist.id,
                name: nameController.text,
                description: descriptionController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog to delete playlist
  void _confirmDeletePlaylist(BuildContext context, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              final playlistViewModel =
                  Provider.of<PlaylistViewModel>(context, listen: false);
              playlistViewModel.deletePlaylist(playlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show dialog to add songs to the playlist
  void _showAddSongsDialog(BuildContext context) {
    final libraryViewModel =
        Provider.of<LibraryViewModel>(context, listen: false);
    final playlistViewModel =
        Provider.of<PlaylistViewModel>(context, listen: false);
    final currentPlaylist =
        playlistViewModel.selectedPlaylist ?? widget.playlist;

    // Get all songs from library that are not in the playlist
    final availableSongs = libraryViewModel.allSongs
        .where((song) => !currentPlaylist.songs.any((s) => s.id == song.id))
        .toList();

    if (availableSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more songs available to add'),
        ),
      );
      return;
    }

    // Track selected songs
    final selectedSongs = <SongModel>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Songs'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSongs.length,
                itemBuilder: (context, index) {
                  final song = availableSongs[index];
                  final isSelected = selectedSongs.contains(song);

                  return CheckboxListTile(
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${song.artist} • ${song.album}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        song.albumArt,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedSongs.add(song);
                        } else {
                          selectedSongs.remove(song);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedSongs.isEmpty
                    ? null
                    : () {
                        for (final song in selectedSongs) {
                          playlistViewModel.addSongToSelectedPlaylist(song);
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added ${selectedSongs.length} songs to playlist'),
                          ),
                        );
                      },
                child: const Text('Add Selected'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build empty state for when the playlist has no songs
  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 72,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'This playlist is empty',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs to get started',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Songs'),
            onPressed: () => _showAddSongsDialog(context),
          ),
        ],
      ),
    );
  }
}
