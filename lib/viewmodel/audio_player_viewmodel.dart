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
    if (songs.isEmpty) return;

    _playlist = songs;
    await _audioService.setPlaylist(songs, initialIndex: initialIndex);
    _currentSong = songs[initialIndex];
    notifyListeners();
  }

  // Play a specific song
  Future<void> playSong(SongModel song) async {
    // Check if the song is already in the playlist
    final index = _playlist.indexWhere((s) => s.id == song.id);

    if (index >= 0) {
      // Song is in the playlist, just seek to it
      await _audioService.seekToIndex(index);
    } else {
      // Song is not in the playlist, load it as a single song
      await loadPlaylist([song]);
    }

    _currentSong = song;

    // Add to recently played songs, avoiding duplicates
    _addToRecentlyPlayed(song);

    await _audioService.play();
    notifyListeners();
  }

  // Play/pause toggle
  Future<void> playOrPause() async {
    await _audioService.playOrPause();
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  // Skip to next song
  Future<void> skipToNext() async {
    await _audioService.next();
    _updateCurrentSong();
  }

  // Skip to previous song
  Future<void> skipToPrevious() async {
    await _audioService.previous();
    _updateCurrentSong();
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

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
