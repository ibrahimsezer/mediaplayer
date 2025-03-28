import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/service/audio_service.dart';

class AudioPlayerViewModel extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  // Current song
  SongModel? _currentSong;
  SongModel? get currentSong => _currentSong;

  // Playlist
  List<SongModel> _playlist = [];
  List<SongModel> get playlist => _playlist;

  // Recently played songs
  List<SongModel> _recentlyPlayedSongs = [];
  List<SongModel> get recentlyPlayedSongs => _recentlyPlayedSongs;

  // Playback state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Current position and duration
  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  // Buffered position
  Duration _bufferedPosition = Duration.zero;
  Duration get bufferedPosition => _bufferedPosition;

  // Shuffle mode
  bool _shuffleModeEnabled = false;
  bool get shuffleModeEnabled => _shuffleModeEnabled;

  // Repeat mode
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  // Volume
  double _volume = 1.0;
  double get volume => _volume;
  set volume(double value) {
    _volume = value;
    _audioService.volume = value;
    notifyListeners();
  }

  // Speed
  double _speed = 1.0;
  double get speed => _speed;
  set speed(double value) {
    _speed = value;
    _audioService.speed = value;
    notifyListeners();
  }

  // Initialize the audio player
  Future<void> init() async {
    await _audioService.init();

    // Listen to position changes
    _audioService.positionDataStream.listen((positionData) {
      _position = positionData.position;
      _bufferedPosition = positionData.bufferedPosition;
      _duration = positionData.duration;
      notifyListeners();
    });

    // Listen to player state changes
    _audioService.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      notifyListeners();
    });
  }

  // Load a playlist of songs
  Future<void> loadPlaylist(List<SongModel> songs,
      {int initialIndex = 0}) async {
    if (songs.isEmpty) {
      log('Attempted to load empty playlist');
      return;
    }

    try {
      // Store the complete playlist for proper playback
      _playlist = List.from(songs);

      // Ensure initialIndex is valid
      if (initialIndex < 0 || initialIndex >= songs.length) {
        initialIndex = 0;
      }

      await _audioService.setPlaylist(songs, initialIndex: initialIndex);

      // Make sure we update the current song even if audio service initialization fails
      _currentSong = songs[initialIndex];

      // Explicitly try to play after loading
      await _audioService.play().catchError((e) {
        log('Error starting playback after loading playlist: $e');
      });

      notifyListeners();
    } catch (e) {
      log('Error loading playlist: $e');
      // Don't rethrow to prevent app freezes
    }
  }

  // Set the current song without reloading the playlist
  // This is useful when we want to update the UI without disrupting playback
  void setCurrentSongWithoutReload(SongModel song) {
    if (_playlist.any((s) => s.id == song.id)) {
      _currentSong = song;
      _addToRecentlyPlayed(song);
      notifyListeners();
    }
  }

  // Play a specific song
  Future<void> playSong(SongModel song) async {
    try {
      // Check if the song is already in the playlist
      final index = _playlist.indexWhere((s) => s.id == song.id);

      if (index >= 0) {
        // Song is in the playlist, just seek to it
        await _audioService.seekToIndex(index);
        _currentSong = song;
      } else {
        // Song is not in the playlist, load it as a single song
        _playlist = [song];
        await _audioService.setPlaylist([song]);
        _currentSong = song;
      }

      // Add to recently played songs, avoiding duplicates
      _addToRecentlyPlayed(song);

      // Explicitly try to play
      await _audioService.play();
      notifyListeners();
    } catch (e) {
      log('Error playing song: $e');
      // Don't rethrow to prevent app freezes
    }
  }

  // Play/pause toggle
  Future<void> playOrPause() async {
    try {
      await _audioService.playOrPause();
    } catch (e) {
      log('Error in play/pause: $e');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e) {
      log('Error seeking: $e');
    }
  }

  // Skip to next song
  Future<void> skipToNext() async {
    try {
      await _audioService.next();
      _updateCurrentSong();
    } catch (e) {
      log('Error skipping to next: $e');
    }
  }

  // Skip to previous song
  Future<void> skipToPrevious() async {
    try {
      await _audioService.previous();
      _updateCurrentSong();
    } catch (e) {
      log('Error skipping to previous: $e');
    }
  }

  // Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _shuffleModeEnabled = !_shuffleModeEnabled;
    await _audioService.setShuffleMode(_shuffleModeEnabled);
    notifyListeners();
  }

  // Change loop mode
  Future<void> changeLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }

    await _audioService.setLoopMode(_loopMode);
    notifyListeners();
  }

  // Update the current song based on the player's index
  void _updateCurrentSong() {
    final index = _audioService.currentIndex;
    if (index != null && index >= 0 && index < _playlist.length) {
      _currentSong = _playlist[index];
      notifyListeners();
    }
  }

  // Add a song to recently played list
  void _addToRecentlyPlayed(SongModel song) {
    // Remove the song if it's already in the list to avoid duplicates
    _recentlyPlayedSongs.removeWhere((s) => s.id == song.id);

    // Add the song to the beginning of the list
    _recentlyPlayedSongs.insert(0, song);

    // Keep only the most recent 20 songs
    if (_recentlyPlayedSongs.length > 20) {
      _recentlyPlayedSongs = _recentlyPlayedSongs.sublist(0, 20);
    }

    notifyListeners();
  }

  // Play a song that's already in the current playlist
  Future<void> playSongInCurrentPlaylist(SongModel song) async {
    try {
      final index = _playlist.indexWhere((s) => s.id == song.id);
      if (index >= 0) {
        // Song is in the playlist, just seek to it
        await _audioService.seekToIndex(index);
        _currentSong = song;

        // Add to recently played
        _addToRecentlyPlayed(song);

        // Ensure playback starts
        if (!_isPlaying) {
          await _audioService.play();
        }

        notifyListeners();
      } else {
        // Fallback to regular play if somehow the song isn't in the playlist
        await playSong(song);
      }
    } catch (e) {
      log('Error playing song in current playlist: $e');
      // Don't rethrow to prevent app freezes
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
