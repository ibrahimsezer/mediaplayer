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
            // Play album
            final audioViewModel =
                Provider.of<AudioPlayerViewModel>(context, listen: false);
            audioViewModel.loadPlaylist(songs);
          },
          size: MediaQuery.of(context).size.width / 2 - 24,
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    final libraryViewModel = Provider.of<LibraryViewModel>(context);

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
            final audioViewModel =
                Provider.of<AudioPlayerViewModel>(context, listen: false);
            audioViewModel.loadPlaylist(songs);
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
}
