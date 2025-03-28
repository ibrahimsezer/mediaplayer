import 'package:flutter/material.dart';
import 'package:mediaplayer/const/app_constants.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/view/pages/home_page.dart';
import 'package:mediaplayer/view/pages/library_page.dart';
import 'package:mediaplayer/view/pages/now_playing_page.dart';
import 'package:mediaplayer/view/pages/playlists_page.dart';
import 'package:mediaplayer/view/pages/search_page.dart';
import 'package:mediaplayer/view/widgets/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  int _currentIndex = 0;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Initialize pages
    _pages.addAll([
      HomePage(
        onSongSelected: _onSongSelected,
        onPlaylistSelected: _onPlaylistSelected,
      ),
      LibraryPage(
        onSongSelected: _onSongSelected,
        onViewAllSongsPressed: () {},
        onViewAllAlbumsPressed: () {},
        onViewAllArtistsPressed: () {},
      ),
      PlaylistsPage(
        onPlaylistSelected: _onPlaylistSelected,
        onCreatePlaylistPressed: () {},
      ),
      SearchPage(
        onSongSelected: _onSongSelected,
      ),
    ]);
  }

  void _onSongSelected(SongModel song) {
    final audioPlayerViewModel =
        Provider.of<AudioPlayerViewModel>(context, listen: false);
    audioPlayerViewModel.playSong(song);
  }

  void _onPlaylistSelected(PlaylistModel playlist) {
    final audioPlayerViewModel =
        Provider.of<AudioPlayerViewModel>(context, listen: false);
    audioPlayerViewModel.loadPlaylist(playlist.songs);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onMiniPlayerTap() {
    final audioPlayerViewModel =
        Provider.of<AudioPlayerViewModel>(context, listen: false);
    if (audioPlayerViewModel.currentSong != null) {
      _openNowPlayingScreen();
    }
  }

  void _openNowPlayingScreen() {
    final audioPlayerViewModel =
        Provider.of<AudioPlayerViewModel>(context, listen: false);
    if (audioPlayerViewModel.currentSong == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingPage(
          song: audioPlayerViewModel.currentSong!,
          isPlaying: audioPlayerViewModel.isPlaying,
          onPlayPausePressed: (isPlaying) {
            if (isPlaying) {
              audioPlayerViewModel.playOrPause();
            } else {
              audioPlayerViewModel.playOrPause();
            }
          },
          onNextPressed: audioPlayerViewModel.skipToNext,
          onPreviousPressed: audioPlayerViewModel.skipToPrevious,
          onShuffleToggled: audioPlayerViewModel.toggleShuffle,
          onRepeatToggled: audioPlayerViewModel.changeLoopMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player (if song is selected)
          if (audioPlayerViewModel.currentSong != null)
            MiniPlayer(
              song: audioPlayerViewModel.currentSong!,
              isPlaying: audioPlayerViewModel.isPlaying,
              onTap: _onMiniPlayerTap,
              onPlayPause: audioPlayerViewModel.playOrPause,
              onNext: audioPlayerViewModel.skipToNext,
            ),

          // Navigation Bar
          NavigationBar(
            onDestinationSelected: _onPageChanged,
            selectedIndex: _currentIndex,
            destinations: AppConstants.navigationDestinations,
            height: 64,
          ),
        ],
      ),
    );
  }
}
