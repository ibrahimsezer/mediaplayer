import 'package:flutter/material.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/widgets/album_card.dart';
import 'package:mediaplayer/view/widgets/playlist_card.dart';

class HomePage extends StatelessWidget {
  final Function(SongModel) onSongSelected;
  final Function(PlaylistModel) onPlaylistSelected;

  const HomePage({
    super.key,
    required this.onSongSelected,
    required this.onPlaylistSelected,
  });

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
                  color: theme.colorScheme.onSurface,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              expandedTitleScale: 1.5,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.brightness_4,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  // Toggle theme
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: theme.colorScheme.onSurface,
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SongModel.mockSongs.length > 5
                    ? 5
                    : SongModel.mockSongs.length,
                itemBuilder: (context, index) {
                  final song = SongModel.mockSongs[index];
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: PlaylistModel.mockPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = PlaylistModel.mockPlaylists[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: PlaylistCard(
                      playlist: playlist,
                      onTap: () => onPlaylistSelected(playlist),
                      isHorizontal: true,
                    ),
                  );
                },
              ),
            ),
          ),

          // For You section (recommended albums)
          _buildSection(
            context: context,
            title: 'Recommended Albums',
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SongModel.mockSongs.length,
                itemBuilder: (context, index) {
                  final song = SongModel.mockSongs[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: AlbumCard(
                      title: song.album,
                      artist: song.artist,
                      coverArt: song.albumArt,
                      onTap: () {},
                    ),
                  );
                },
              ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      textStyle: theme.textTheme.labelLarge,
                    ),
                    child: Text('View All'),
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
