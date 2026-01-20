import 'package:flutter/material.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/song_tile.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';

class SearchPage extends StatefulWidget {
  final Function(SongModel) onSongSelected;

  const SearchPage({
    super.key,
    required this.onSongSelected,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<SongModel> get _filteredSongs {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    return SongModel.mockSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query);
    }).toList();
  }

  // Get unique albums from filtered songs
  Map<String, List<SongModel>> get _filteredAlbums {
    final albums = <String, List<SongModel>>{};
    for (final song in _filteredSongs) {
      if (!albums.containsKey(song.album)) {
        albums[song.album] = [];
      }
      albums[song.album]!.add(song);
    }
    return albums;
  }

  // Get unique artists from filtered songs
  Map<String, List<SongModel>> get _filteredArtists {
    final artists = <String, List<SongModel>>{};
    for (final song in _filteredSongs) {
      if (!artists.containsKey(song.artist)) {
        artists[song.artist] = [];
      }
      artists[song.artist]!.add(song);
    }
    return artists;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs, albums, artists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Empty state
          if (_searchQuery.isEmpty) _buildEmptyState(context),

          // No results state
          if (_searchQuery.isNotEmpty && _filteredSongs.isEmpty)
            _buildNoResultsState(context),

          // Search results
          if (_filteredSongs.isNotEmpty)
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.only(bottom: 80), // Space for mini player
                children: [
                  // Songs section
                  if (_filteredSongs.isNotEmpty) ...[
                    _buildSectionHeader('Songs'),
                    ...List.generate(
                      _filteredSongs.length > 3 ? 3 : _filteredSongs.length,
                      (index) => SongTile(
                        song: _filteredSongs[index],
                        isPlaying: false,
                        onTap: () =>
                            widget.onSongSelected(_filteredSongs[index]),
                      ),
                    ),
                    if (_filteredSongs.length > 3)
                      _buildViewAllButton(context, 'Songs'),
                  ],

                  // Albums section
                  if (_filteredAlbums.isNotEmpty) ...[
                    _buildSectionHeader('Albums'),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredAlbums.length,
                        itemBuilder: (context, index) {
                          final album = _filteredAlbums.keys.elementAt(index);
                          final songs = _filteredAlbums[album]!;
                          final representative = songs.first;

                          return Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: AlbumCard(
                              title: album,
                              artist: representative.artist,
                              coverArt: representative.albumArt,
                              onTap: () {
                                // Navigate to album detail
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Artists section
                  if (_filteredArtists.isNotEmpty) ...[
                    _buildSectionHeader('Artists'),
                    ...List.generate(
                      _filteredArtists.length > 3 ? 3 : _filteredArtists.length,
                      (index) {
                        final artist = _filteredArtists.keys.elementAt(index);
                        final songs = _filteredArtists[artist]!;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(songs.first.albumArt),
                          ),
                          title: Text(artist),
                          subtitle: Text('${songs.length} songs'),
                          onTap: () {
                            // Navigate to artist detail
                          },
                        );
                      },
                    ),
                    if (_filteredArtists.length > 3)
                      _buildViewAllButton(context, 'Artists'),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for music',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Find your favorite songs, albums, and artists',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off,
              size: 80,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleLarge,
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context, String type) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Navigate to full list
        },
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.labelLarge,
        ),
        child: Text('View all $type'),
      ),
    );
  }
}
