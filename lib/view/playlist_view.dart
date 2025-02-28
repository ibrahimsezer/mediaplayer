import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _playSong(int index) async {
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);
    await mediaPlayer.audioPlayer.seek(Duration.zero, index: index);
    mediaPlayer.audioPlayer.play();
    mediaPlayer.currentIndex = index;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            Expanded(
              child: Consumer<MediaPlayerViewModel>(
                builder: (context, mediaPlayer, _) {
                  if (mediaPlayer.playlist.sequence.length == 0) {
                    return _buildEmptyState();
                  }
                  return _buildPlaylist(mediaPlayer);
                },
              ),
            ), /*
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SlidePageAction(
                pageName: MediaPlayerView(),
              ),
            )*/
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Consumer<MediaPlayerViewModel>(
        builder: (context, mediaPlayer, _) {
          return Text(
            mediaPlayer.currentPlaylist ?? 'All Songs',
            style: Theme.of(context).textTheme.titleLarge,
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () async {
            try {
              final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                context,
                listen: false,
              );
              await mediaPlayer.loadLocalSongs();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading songs: $e')),
              );
            }
          },
          icon: Icon(Icons.add),
          tooltip: 'Add Songs',
        ),
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => _buildSortOptionsSheet(),
            );
          },
          icon: Icon(Icons.sort),
          tooltip: 'Sort Playlist',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search songs...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPlaylist(MediaPlayerViewModel mediaPlayer) {
    final filteredIndices = List<int>.generate(
      mediaPlayer.playlist.sequence.length,
      (index) => index,
    ).where((index) {
      if (index >= mediaPlayer.songNames.length) return false;
      final songName = mediaPlayer.songNames[index].toLowerCase();
      return songName.contains(_searchQuery);
    }).toList();

    return ReorderableListView.builder(
      itemCount: filteredIndices.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      onReorder: mediaPlayer.reorderPlaylist,
      itemBuilder: (context, index) {
        final originalIndex = filteredIndices[index];
        final isPlaying = mediaPlayer.currentIndex == originalIndex;
        final songName = mediaPlayer.songNames[originalIndex];

        return Dismissible(
          key: ValueKey(originalIndex),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => mediaPlayer.removeFromPlaylist(originalIndex),
          child: Card(
            elevation: isPlaying ? 4 : 1,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isPlaying
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              title: Text(
                songName,
                style: TextStyle(
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Local Audio',
                style: TextStyle(fontSize: 12),
              ),
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    color: isPlaying
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  if (isPlaying)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => _showSongOptions(context, originalIndex),
                  ),
                  Icon(Icons.drag_handle),
                ],
              ),
              onTap: () => _playSong(originalIndex),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Your playlist is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add some songs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                await mediaPlayer.loadLocalSongs();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading songs: $e')),
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

  Widget _buildSortOptionsSheet() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.sort_by_alpha),
            title: Text('Sort by Name'),
            onTap: () async {
              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                await mediaPlayer.sortByName();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sorting playlist: $e')),
                );
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Sort by Date Added (Newest First)'),
            onTap: () async {
              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                await mediaPlayer.sortByDateAdded();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sorting playlist: $e')),
                );
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Sort by Date Added (Oldest First)'),
            onTap: () async {
              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                // First sort by newest, then reverse
                await mediaPlayer.sortByDateAdded();
                await mediaPlayer.sortByDateAdded();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sorting playlist: $e')),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play Next'),
              onTap: () {
                // Implement play next
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add to Another Playlist'),
              onTap: () {
                // Implement add to playlist
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Song Info'),
              onTap: () {
                // Show song info
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
