import 'package:flutter/material.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/song_tile.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/viewmodel/library_viewmodel.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';

class SearchPage extends StatefulWidget {
  final Function(SongModel) onSongSelected;

  const SearchPage({
    Key? key,
    required this.onSongSelected,
  }) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Get filtered songs from library based on search query
  List<SongModel> _getFilteredSongs() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return libraryViewModel.allSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query);
    }).toList();
  }

  // Get unique albums from filtered songs
  List<String> _getFilteredAlbums() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return libraryViewModel.allAlbums.where((album) {
      return album.toLowerCase().contains(query);
    }).toList();
  }

  // Get unique artists from filtered songs
  List<String> _getFilteredArtists() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return libraryViewModel.allArtists.where((artist) {
      return artist.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);
    final playlistViewModel = Provider.of<PlaylistViewModel>(context);

    // Filter the songs, albums, and artists based on the search query
    final filteredSongs = _getFilteredSongs();
    final filteredAlbums = _getFilteredAlbums();
    final filteredArtists = _getFilteredArtists();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for songs, albums, or artists',
            border: InputBorder.none,
            icon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      body: _buildBody(context, libraryViewModel, audioPlayerViewModel,
          playlistViewModel, filteredSongs, filteredAlbums, filteredArtists),
    );
  }

  Widget _buildBody(
      BuildContext context,
      LibraryViewModel libraryViewModel,
      AudioPlayerViewModel audioPlayerViewModel,
      PlaylistViewModel playlistViewModel,
      List<SongModel> filteredSongs,
      List<String> filteredAlbums,
      List<String> filteredArtists) {
    // Check if library is empty
    if (libraryViewModel.allSongs.isEmpty) {
      return _buildLibraryEmptyState(context);
    }

    // Check if search query is empty
    if (_searchQuery.isEmpty) {
      return _buildNoSearchQueryState(context);
    }

    // Check if no results found
    if (filteredSongs.isEmpty &&
        filteredAlbums.isEmpty &&
        filteredArtists.isEmpty) {
      return _buildNoResultsState(context);
    }

    // Build search results
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Songs section
          if (filteredSongs.isNotEmpty) ...[
            _buildSectionHeader(
                'Songs',
                filteredSongs.length > 5
                    ? () => _showAllSongs(
                        context,
                        filteredSongs,
                        'Search Results',
                        audioPlayerViewModel,
                        playlistViewModel)
                    : null),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSongs.length > 5 ? 5 : filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return SongTile(
                  song: song,
                  isPlaying: audioPlayerViewModel.currentSong?.id == song.id &&
                      audioPlayerViewModel.isPlaying,
                  onTap: () {
                    widget.onSongSelected(song);
                    audioPlayerViewModel.playSong(song);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Albums section
          if (filteredAlbums.isNotEmpty) ...[
            _buildSectionHeader('Albums', null),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAlbums.length,
                itemBuilder: (context, index) {
                  final album = filteredAlbums[index];
                  final albumSongs = libraryViewModel.getSongsByAlbum(album);
                  final coverArt = albumSongs.isNotEmpty
                      ? albumSongs.first.albumArt
                      : 'assets/images/default_album.png';
                  final artist = albumSongs.isNotEmpty
                      ? albumSongs.first.artist
                      : 'Unknown Artist';

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AlbumCard(
                      title: album,
                      artist: artist,
                      coverArt: coverArt,
                      onTap: () {
                        // Play album
                        if (albumSongs.isNotEmpty) {
                          audioPlayerViewModel.loadPlaylist(albumSongs);
                          widget.onSongSelected(albumSongs.first);
                        }
                      },
                      size: 140,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Artists section
          if (filteredArtists.isNotEmpty) ...[
            _buildSectionHeader('Artists', null),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = filteredArtists[index];
                  final artistSongs = libraryViewModel.getSongsByArtist(artist);
                  final coverArt = artistSongs.isNotEmpty
                      ? artistSongs.first.albumArt
                      : 'assets/images/default_artist.png';

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Play artist songs
                            if (artistSongs.isNotEmpty) {
                              audioPlayerViewModel.loadPlaylist(artistSongs);
                              widget.onSongSelected(artistSongs.first);
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(coverArt),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${artistSongs.length} songs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Show all songs in a full screen modal
  void _showAllSongs(
      BuildContext context,
      List<SongModel> songs,
      String title,
      AudioPlayerViewModel audioPlayerViewModel,
      PlaylistViewModel playlistViewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          // Play all songs
                          if (songs.isNotEmpty) {
                            audioPlayerViewModel.loadPlaylist(songs);
                            widget.onSongSelected(songs.first);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_add),
                        onPressed: () {
                          // Add songs to playlist
                          Navigator.pop(context);
                          _showAddToPlaylistDialog(
                              context, songs, playlistViewModel);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Song list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongTile(
                    song: song,
                    isPlaying:
                        audioPlayerViewModel.currentSong?.id == song.id &&
                            audioPlayerViewModel.isPlaying,
                    onTap: () {
                      widget.onSongSelected(song);
                      audioPlayerViewModel.playSong(song);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog to add songs to playlist
  void _showAddToPlaylistDialog(BuildContext context, List<SongModel> songs,
      PlaylistViewModel playlistViewModel) {
    if (playlistViewModel.playlists.isEmpty) {
      // No playlists exist, create one first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Playlists'),
          content: const Text(
              'You don\'t have any playlists yet. Create one first?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, playlistViewModel, songs);
              },
              child: const Text('CREATE'),
            ),
          ],
        ),
      );
      return;
    }

    // Show list of playlists to choose from
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistViewModel.playlists.length +
                1, // +1 for "Create New Playlist" option
            itemBuilder: (context, index) {
              if (index == playlistViewModel.playlists.length) {
                // Last item: Create new playlist
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Playlist'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistDialog(
                        context, playlistViewModel, songs);
                  },
                );
              }

              final playlist = playlistViewModel.playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length} songs'),
                onTap: () {
                  // Add songs to this playlist
                  for (final song in songs) {
                    playlistViewModel.addSongToPlaylist(playlist.id, song);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Added ${songs.length} songs to ${playlist.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Show dialog to create a new playlist
  void _showCreatePlaylistDialog(BuildContext context,
      PlaylistViewModel playlistViewModel, List<SongModel> songs) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter a name for your playlist',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter a description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                // Create playlist and add songs
                final playlist = await playlistViewModel.createPlaylist(
                  nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                if (playlist != null && songs.isNotEmpty) {
                  for (final song in songs) {
                    await playlistViewModel.addSongToPlaylist(
                        playlist.id, song);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Created playlist ${playlist.name} with ${songs.length} songs'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildLibraryEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_music,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your library is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some music to your library first',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Go to Library'),
            onPressed: () {
              // Navigate to the library tab
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchQueryState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Search for songs, albums, or artists',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No matches for "$_searchQuery"',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
