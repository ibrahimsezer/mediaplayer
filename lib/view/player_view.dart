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

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  int _currentIndex = 0;

  // Mock currently playing song
  SongModel? _currentSong;

  // Mock playing state
  bool _isPlaying = false;

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
    setState(() {
      _currentSong = song;
      _isPlaying = true;
    });

    // In a real app, this would start playback
  }

  void _onPlaylistSelected(PlaylistModel playlist) {
    // In a real app, this would navigate to a playlist detail page
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    // In a real app, this would toggle playback
  }

  void _playNextSong() {
    // In a real app, this would play the next song
    if (_currentSong != null) {
      final currentIndex =
          SongModel.mockSongs.indexWhere((song) => song.id == _currentSong!.id);
      if (currentIndex != -1 && currentIndex < SongModel.mockSongs.length - 1) {
        setState(() {
          _currentSong = SongModel.mockSongs[currentIndex + 1];
        });
      }
    }
  }

  void _playPreviousSong() {
    // In a real app, this would play the previous song
    if (_currentSong != null) {
      final currentIndex =
          SongModel.mockSongs.indexWhere((song) => song.id == _currentSong!.id);
      if (currentIndex > 0) {
        setState(() {
          _currentSong = SongModel.mockSongs[currentIndex - 1];
        });
      }
    }
  }

  void _onMiniPlayerTap() {
    if (_currentSong != null) {
      _openNowPlayingScreen();
    }
  }

  void _openNowPlayingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingPage(
          song: _currentSong!,
          isPlaying: _isPlaying,
          onPlayPausePressed: (isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          },
          onNextPressed: _playNextSong,
          onPreviousPressed: _playPreviousSong,
          onShuffleToggled: () {},
          onRepeatToggled: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player (if song is selected)
          if (_currentSong != null)
            MiniPlayer(
              song: _currentSong!,
              isPlaying: _isPlaying,
              onTap: _onMiniPlayerTap,
              onPlayPause: _togglePlayPause,
              onNext: _playNextSong,
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
