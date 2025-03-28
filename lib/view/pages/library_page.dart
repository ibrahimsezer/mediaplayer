import 'package:flutter/material.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/song_tile.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/viewmodel/library_viewmodel.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';

class LibraryPage extends StatefulWidget {
  final Function(SongModel) onSongSelected;
  final VoidCallback onViewAllSongsPressed;
  final VoidCallback onViewAllAlbumsPressed;
  final VoidCallback onViewAllArtistsPressed;

  const LibraryPage({
    Key? key,
    required this.onSongSelected,
    required this.onViewAllSongsPressed,
    required this.onViewAllAlbumsPressed,
    required this.onViewAllArtistsPressed,
  }) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Show an options dialog for adding music
  void _showAddMusicOptions(BuildContext context, LibraryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Music'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose how you want to add music',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _scanDirectory(viewModel);
            },
            child: const Text('Scan Folder'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickFiles(viewModel);
            },
            child: const Text('Select Files'),
          ),
        ],
      ),
    );
  }

  // Scan a directory for music files
  Future<void> _scanDirectory(LibraryViewModel viewModel) async {
    final hasPermission = await viewModel.requestPermissionsAndScan();
    if (hasPermission) {
      await viewModel.pickAndScanDirectory();
      if (viewModel.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.error)),
        );
      } else if (viewModel.allSongs.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Added ${viewModel.allSongs.length} songs to your library')),
        );
      }
    }
  }

  // Pick individual music files
  Future<void> _pickFiles(LibraryViewModel viewModel) async {
    final currentSongCount = viewModel.allSongs.length;
    await viewModel.pickAndAddMusicFiles();

    if (mounted) {
      if (viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.error)),
        );
      } else if (viewModel.allSongs.length > currentSongCount) {
        final newSongs = viewModel.allSongs.length - currentSongCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $newSongs songs to your library')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final libraryViewModel = Provider.of<LibraryViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMusicOptions(context, libraryViewModel),
            tooltip: 'Add Music',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
          labelStyle: theme.textTheme.titleSmall,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.titleSmall?.color,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: libraryViewModel.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading music...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : libraryViewModel.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        libraryViewModel.error,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder),
                        label: const Text('Scan Directory'),
                        onPressed: () => _scanDirectory(libraryViewModel),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.audio_file),
                        label: const Text('Select Files'),
                        onPressed: () => _pickFiles(libraryViewModel),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Songs tab
                    _buildSongsTab(),

                    // Albums tab
                    _buildAlbumsTab(),

                    // Artists tab
                    _buildArtistsTab(),
                  ],
                ),
    );
  }

  Widget _buildSongsTab() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);

    if (libraryViewModel.allSongs.isEmpty) {
      return _buildEmptyState('No songs in your library yet', Icons.music_note);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for mini player
      itemCount: libraryViewModel.allSongs.length,
      itemBuilder: (context, index) {
        final song = libraryViewModel.allSongs[index];
        return SongTile(
          song: song,
          isPlaying: audioPlayerViewModel.currentSong?.id == song.id &&
              audioPlayerViewModel.isPlaying,
          onTap: () => widget.onSongSelected(song),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);

    if (libraryViewModel.allAlbums.isEmpty) {
      return _buildEmptyState('No albums in your library yet', Icons.album);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: libraryViewModel.allAlbums.length,
      itemBuilder: (context, index) {
        final album = libraryViewModel.allAlbums[index];
        final songs = libraryViewModel.getSongsByAlbum(album);
        final representative = songs.first;

        return AlbumCard(
          title: album,
          artist: representative.artist,
          coverArt: representative.albumArt,
          onTap: () {
            // Play album songs
            audioPlayerViewModel.loadPlaylist(songs);
            if (songs.isNotEmpty) {
              widget.onSongSelected(songs.first);
            }

            // Show album details in bottom sheet
            _showAlbumDetails(context, album, songs, audioPlayerViewModel);
          },
          size: MediaQuery.of(context).size.width / 2 - 24,
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);

    if (libraryViewModel.allArtists.isEmpty) {
      return _buildEmptyState('No artists in your library yet', Icons.person);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for mini player
      itemCount: libraryViewModel.allArtists.length,
      itemBuilder: (context, index) {
        final artist = libraryViewModel.allArtists[index];
        final songs = libraryViewModel.getSongsByArtist(artist);

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(songs.first.albumArt),
          ),
          title: Text(artist),
          subtitle: Text('${songs.length} songs'),
          onTap: () {
            // Play all songs by this artist
            audioPlayerViewModel.loadPlaylist(songs);
            if (songs.isNotEmpty) {
              widget.onSongSelected(songs.first);
            }

            // Show artist details in bottom sheet
            _showArtistDetails(context, artist, songs, audioPlayerViewModel);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);
    final libraryViewModel =
        Provider.of<LibraryViewModel>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Music'),
            onPressed: () => _showAddMusicOptions(context, libraryViewModel),
          ),
        ],
      ),
    );
  }

  // Show album details bottom sheet
  void _showAlbumDetails(BuildContext context, String album,
      List<SongModel> songs, AudioPlayerViewModel audioPlayerViewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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

            // Album header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Album art
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        songs.first.albumArt,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Album info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          songs.first.artist,
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} songs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Play button
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    iconSize: 48,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      audioPlayerViewModel.loadPlaylist(songs);
                      if (songs.isNotEmpty) {
                        widget.onSongSelected(songs.first);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Songs list
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

  // Show artist details bottom sheet
  void _showArtistDetails(BuildContext context, String artist,
      List<SongModel> songs, AudioPlayerViewModel audioPlayerViewModel) {
    // Group songs by album
    final albums = <String, List<SongModel>>{};
    for (final song in songs) {
      if (!albums.containsKey(song.album)) {
        albums[song.album] = [];
      }
      albums[song.album]!.add(song);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => DefaultTabController(
          length: 2,
          child: Column(
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

              // Artist header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Artist image
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(songs.first.albumArt),
                    ),

                    const SizedBox(width: 16),

                    // Artist info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${songs.length} songs · ${albums.length} albums',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    // Play button
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled),
                      iconSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        audioPlayerViewModel.loadPlaylist(songs);
                        if (songs.isNotEmpty) {
                          widget.onSongSelected(songs.first);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Tab bar
              TabBar(
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodyLarge?.color,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    // Songs tab
                    ListView.builder(
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

                    // Albums tab
                    GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final albumName = albums.keys.elementAt(index);
                        final albumSongs = albums[albumName]!;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showAlbumDetails(context, albumName, albumSongs,
                                audioPlayerViewModel);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Album art
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.asset(
                                    albumSongs.first.albumArt,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // Album title
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, left: 4.0, right: 4.0),
                                child: Text(
                                  albumName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Album info
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 4.0, right: 4.0),
                                child: Text(
                                  '${albumSongs.length} songs',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
