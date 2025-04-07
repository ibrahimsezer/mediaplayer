import 'package:flutter/material.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';
import 'package:mediaplayer/view/widgets/playlist_card.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/library_viewmodel.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';

class HomePage extends StatelessWidget {
  final Function(SongModel) onSongSelected;
  final Function(PlaylistModel) onPlaylistSelected;

  const HomePage({
    Key? key,
    required this.onSongSelected,
    required this.onPlaylistSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Rhythm',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              expandedTitleScale: 1.5,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.brightness_4,
                  color: theme.colorScheme.onBackground,
                ),
                onPressed: () {
                  // Toggle theme
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: theme.colorScheme.onBackground,
                ),
                onPressed: () {
                  // Open settings
                },
              ),
            ],
          ),

          // Welcome message
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Good ${_getTimeOfDay()}, Music Lover!',
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),

          // Recently played songs
          _buildSection(
            context: context,
            title: 'Recently Played',
            child: SizedBox(
              height: 80,
              child: Consumer<AudioPlayerViewModel>(
                  builder: (context, audioViewModel, child) {
                final recentSongs = audioViewModel.recentlyPlayedSongs;

                if (recentSongs.isEmpty) {
                  return const Center(
                    child: Text('No recently played songs'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentSongs.length > 5 ? 5 : recentSongs.length,
                  itemBuilder: (context, index) {
                    final song = recentSongs[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSongSelected(song),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    song.albumArt,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        song.title,
                                        style: theme.textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        song.artist,
                                        style: theme.textTheme.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          // Featured playlists
          _buildSection(
            context: context,
            title: 'Your Playlists',
            viewAllAction: () {
              // Navigate to playlists page
            },
            child: SizedBox(
              height: 180,
              child: Consumer<PlaylistViewModel>(
                  builder: (context, playlistViewModel, child) {
                final playlists = playlistViewModel.playlists;

                if (playlists.isEmpty) {
                  return const Center(
                    child: Text('No playlists found'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: PlaylistCard(
                        playlist: playlist,
                        onTap: () => onPlaylistSelected(playlist),
                        isHorizontal: true,
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          // For You section (recommended albums)
          _buildSection(
            context: context,
            title: 'Recommended Albums',
            child: SizedBox(
              height: 220,
              child: Consumer<LibraryViewModel>(
                  builder: (context, libraryViewModel, child) {
                final albums = libraryViewModel.allAlbums;

                if (albums.isEmpty) {
                  return const Center(
                    child: Text('No albums found'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final songs = libraryViewModel.getSongsByAlbum(album);
                    final representative = songs.first;

                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: AlbumCard(
                        title: album,
                        artist: representative.artist,
                        coverArt: representative.albumArt,
                        onTap: () {
                          // Play album
                          final audioViewModel =
                              Provider.of<AudioPlayerViewModel>(context,
                                  listen: false);
                          audioViewModel.loadPlaylist(songs);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for mini player
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
    VoidCallback? viewAllAction,
  }) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
                if (viewAllAction != null)
                  TextButton(
                    onPressed: viewAllAction,
                    child: Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      textStyle: theme.textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else if (hour < 20) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }
}
