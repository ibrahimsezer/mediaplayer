import 'package:flutter/material.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/song_tile.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
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
      body: TabBarView(
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
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for mini player
      itemCount: SongModel.mockSongs.length,
      itemBuilder: (context, index) {
        final song = SongModel.mockSongs[index];
        return SongTile(
          song: song,
          isPlaying: false, // This would be dynamic based on what's playing
          onTap: () => widget.onSongSelected(song),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    // Extract unique albums from songs
    final albums = <String, List<SongModel>>{};
    for (final song in SongModel.mockSongs) {
      if (!albums.containsKey(song.album)) {
        albums[song.album] = [];
      }
      albums[song.album]!.add(song);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums.keys.elementAt(index);
        final songs = albums[album]!;
        final representative = songs.first;

        return AlbumCard(
          title: album,
          artist: representative.artist,
          coverArt: representative.albumArt,
          onTap: () {
            // Navigate to album detail view
          },
          size: MediaQuery.of(context).size.width / 2 - 24,
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    // Extract unique artists from songs
    final artists = <String, List<SongModel>>{};
    for (final song in SongModel.mockSongs) {
      if (!artists.containsKey(song.artist)) {
        artists[song.artist] = [];
      }
      artists[song.artist]!.add(song);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for mini player
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists.keys.elementAt(index);
        final songs = artists[artist]!;

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(songs.first.albumArt),
          ),
          title: Text(artist),
          subtitle: Text('${songs.length} songs'),
          onTap: () {
            // Navigate to artist detail view
          },
        );
      },
    );
  }
}
