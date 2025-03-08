import 'package:flutter/material.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/music_player_viewmodel.dart';
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
            _buildPlaylistTabs(),
            Consumer<MusicPlayerViewModel>(
                builder: (context, viewModel, child) {
              return Expanded(
                child: ListView.builder(
                  itemCount: viewModel.songs.length,
                  itemBuilder: (context, index) {
                    final song = viewModel.songs[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      onTap: () => viewModel.playSong(song),
                    );
                  },
                ),
              );
            }), /*
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
          onPressed: () => _showCreatePlaylistDialog(),
          icon: Icon(Icons.playlist_add),
          tooltip: 'Create Playlist',
        ),
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

  Widget _buildPlaylistTabs() {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, mediaPlayer, _) {
        return SizedBox(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(
                  'Your Playlists',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  children: [
                    // All Songs Card
                    _buildPlaylistCard(
                      context,
                      'All Songs',
                      mediaPlayer.songNames.length,
                      isSelected: mediaPlayer.currentPlaylist == null,
                      onTap: () async {
                        try {
                          await mediaPlayer.switchToPlaylist('All Songs');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error switching playlist: $e')),
                          );
                        }
                      },
                    ),
                    // User Created Playlists
                    ...mediaPlayer.playlists.entries.map(
                      (entry) => _buildPlaylistCard(
                        context,
                        entry.key,
                        entry.value.length,
                        isSelected: mediaPlayer.currentPlaylist == entry.key,
                        onTap: () async {
                          try {
                            await mediaPlayer.switchToPlaylist(entry.key);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error switching playlist: $e')),
                            );
                          }
                        },
                        onLongPress: () =>
                            _showPlaylistOptions(context, entry.key),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistCard(
    BuildContext context,
    String name,
    int songCount, {
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Container(
      width: 150,
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color:
            isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 24,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$songCount songs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylist(MediaPlayerViewModel mediaPlayer) {
    final filteredIndices = List<int>.generate(
      mediaPlayer.songs.length,
      (index) => index,
    ).where((index) {
      final songName = mediaPlayer.songs[index].title.toLowerCase();
      return songName.contains(_searchQuery);
    }).toList();

    return ReorderableListView.builder(
      itemCount: filteredIndices.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      onReorder: mediaPlayer.reorderPlaylist,
      itemBuilder: (context, index) {
        final originalIndex = filteredIndices[index];
        final isPlaying = mediaPlayer.currentIndex == originalIndex;
        final songName = mediaPlayer.songs[originalIndex].title;

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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);

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
                // TODO: Implement play next
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Song Info'),
              onTap: () {
                // TODO: Show song info
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(int songIndex) {
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to Playlist'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...mediaPlayer.playlists.keys.map(
                (playlistName) => ListTile(
                  leading: Icon(Icons.playlist_play),
                  title: Text(playlistName),
                  onTap: () async {
                    try {
                      final audioSource = mediaPlayer.songs[songIndex];
                      if (audioSource is IndexedAudioSource) {
                        final uri = (audioSource as UriAudioSource).uri;
                        await mediaPlayer.addToPlaylist(playlistName, uri.path);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Song added to "$playlistName"')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error adding song to playlist: $e')),
                      );
                    }
                  },
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Create New Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Playlist'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter playlist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a playlist name')),
                );
                return;
              }

              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                await mediaPlayer.createPlaylist(name);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist "$name" created')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating playlist: $e')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, String playlistName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Rename Playlist'),
              onTap: () {
                Navigator.pop(context);
                _showRenamePlaylistDialog(playlistName);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Playlist'),
              onTap: () async {
                try {
                  final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                    context,
                    listen: false,
                  );
                  await mediaPlayer.deletePlaylist(playlistName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playlist "$playlistName" deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting playlist: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenamePlaylistDialog(String oldName) {
    final TextEditingController controller =
        TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new playlist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a playlist name')),
                );
                return;
              }

              try {
                final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                  context,
                  listen: false,
                );
                await mediaPlayer.renamePlaylist(oldName, newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist renamed to "$newName"')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error renaming playlist: $e')),
                );
              }
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }
}
