import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;
import 'package:mediaplayer/model/song_model.dart';

class MediaPlayerViewModel extends ChangeNotifier {
  final List<SongModel> _songs = [];

  List<SongModel> get songs => _songs;
  List<String> get songNames => _songs.map((song) => song.title).toList();
  List<MediaItem> get metadata => _songs.map((song) => song.metadata).toList();
  List<AudioSource> get audioSources => _songs.map((song) => song.audioSource).toList();

  int _currentIndex = 0;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  late final ConcatenatingAudioSource _playlist;
  
  // Initialize the playlist
  ConcatenatingAudioSource get playlist => _playlist;

  get isShuffleMode => _isShuffleMode;
  get isRepeatMode => _isRepeatMode;

  int get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  get audioPlayer => _audioPlayer;

  // Map to store multiple playlists
  final Map<String, List<SongModel>> _playlists = {};
  String? _currentPlaylist;

  Map<String, List<String>> get playlists => 
      _playlists.map((key, value) => MapEntry(key, value.map((song) => song.title).toList()));
  String? get currentPlaylist => _currentPlaylist;

  MediaPlayerViewModel() {
    _playlist = ConcatenatingAudioSource(children: []);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (_songs.isNotEmpty) {
        await _playlist.addAll(audioSources);
        await _audioPlayer.setAudioSource(_playlist);
      }
      await _audioPlayer.setLoopMode(LoopMode.off);

      // Listen to current song changes
      _audioPlayer.currentIndexStream.listen((index) {
        if (index != null) {
          _currentIndex = index;
          notifyListeners();
        }
      });

      // Listen to playlist changes
      _audioPlayer.sequenceStateStream.listen((_) {
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing player: $e");
    }
  }

  Future<void> _loadLocalSongs() async {
    try {
      final storageStatus = await Permission.storage.request();
      final audioStatus = await Permission.audio.request();

      if (storageStatus.isGranted || audioStatus.isGranted) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );

        if (result != null && result.paths.isNotEmpty) {
          List<SongModel> newSongs = [];
          List<AudioSource> newAudioSources = [];

          // Add new songs and their metadata
          for (String? filePath in result.paths) {
            if (filePath != null) {
              // Create a SongModel from the file path
              final songModel = SongModel.fromFilePath(filePath);
              
              newSongs.add(songModel);
              _songs.add(songModel);
              newAudioSources.add(songModel.audioSource);
            }
          }

          await _playlist.addAll(newAudioSources);

          if (_audioPlayer.audioSource == null) {
            await _audioPlayer.setAudioSource(_playlist);
          }

          notifyListeners();
        }
      } else {
        debugPrint("Permission denied");
      }
    } catch (e) {
      debugPrint("Error loading songs: $e");
      rethrow;
    }
  }

  Future<void> loadLocalSongs() async {
    await _loadLocalSongs();
  }

  void toggleShuffleMode() {
    _isShuffleMode = !_isShuffleMode;
    _audioPlayer.setShuffleModeEnabled(_isShuffleMode);
    notifyListeners();
  }

  void toggleRepeatMode() {
    _isRepeatMode = !_isRepeatMode;
    _audioPlayer.setLoopMode(_isRepeatMode ? LoopMode.all : LoopMode.off);
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    if (_playlists.containsKey(name)) {
      throw Exception('A playlist with this name already exists');
    }

    _playlists[name] = [];
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistName, String filePath) async {
    try {
      if (!_playlists.containsKey(playlistName)) {
        throw Exception('Playlist not found');
      }

      // Create a SongModel from the file path
      final songModel = SongModel.fromFilePath(filePath);
      
      _playlists[playlistName]!.add(songModel);

      // If this is the current playlist, update the main playlist
      if (_currentPlaylist == playlistName) {
        await _playlist.add(songModel.audioSource);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error adding to playlist: $e");
      rethrow;
    }
  }

  Future<void> switchToPlaylist(String playlistName) async {
    try {
      if (!_playlists.containsKey(playlistName)) {
        throw Exception('Playlist not found');
      }

      _songs.clear();
      await _playlist.clear();

      _songs.addAll(_playlists[playlistName]!);
      List<AudioSource> audioSources = _songs.map((song) => song.audioSource).toList();
      await _playlist.addAll(audioSources);

      _currentPlaylist = playlistName;
      _currentIndex = 0;

      if (_songs.isNotEmpty) {
        await _audioPlayer.setAudioSource(_playlist);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error switching playlist: $e");
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistName) async {
    try {
      if (!_playlists.containsKey(playlistName)) {
        throw Exception('Playlist not found');
      }

      _playlists.remove(playlistName);

      if (_currentPlaylist == playlistName) {
        _currentPlaylist = null;
        _songs.clear();
        await _playlist.clear();
        _currentIndex = 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting playlist: $e");
      rethrow;
    }
  }

  Future<void> removeFromPlaylist(int index) async {
    try {
      if (index >= 0 && index < _songs.length) {
        await _playlist.removeAt(index);
        _songs.removeAt(index);

        if (_songs.isEmpty) {
          _currentIndex = 0;
        } else if (_currentIndex >= _songs.length) {
          _currentIndex = _songs.length - 1;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error removing from playlist: $e");
      rethrow;
    }
  }

  Future<void> reorderPlaylist(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      if (oldIndex >= 0 &&
          oldIndex < _songs.length &&
          newIndex >= 0 &&
          newIndex < _songs.length) {
        await _playlist.move(oldIndex, newIndex);

        final song = _songs.removeAt(oldIndex);
        _songs.insert(newIndex, song);

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reordering playlist: $e");
      rethrow;
    }
  }

  Future<void> sortByName() async {
    try {
      final indices = List.generate(_songs.length, (index) => index);
      indices.sort((a, b) =>
          _songs[a].title.toLowerCase().compareTo(_songs[b].title.toLowerCase()));

      await _reorderPlaylistByIndices(indices);
      notifyListeners();
    } catch (e) {
      debugPrint("Error sorting by name: $e");
      rethrow;
    }
  }

  Future<void> sortByDateAdded() async {
    try {
      // Since we maintain the order of addition in our lists,
      // we just need to reverse the current order for newest first
      final indices =
          List.generate(_songs.length, (index) => _songs.length - 1 - index);

      await _reorderPlaylistByIndices(indices);
      notifyListeners();
    } catch (e) {
      debugPrint("Error sorting by date: $e");
      rethrow;
    }
  }

  Future<void> _reorderPlaylistByIndices(List<int> indices) async {
    if (indices.isEmpty) return;

    final newSongs = <SongModel>[];

    for (final index in indices) {
      newSongs.add(_songs[index]);
    }

    _songs.clear();
    await _playlist.clear();

    _songs.addAll(newSongs);
    await _playlist.addAll(newSongs.map((song) => song.audioSource).toList());

    if (_currentIndex >= _songs.length) {
      _currentIndex = 0;
    }
  }

  Future<void> renamePlaylist(String oldName, String newName) async {
    try {
      if (!_playlists.containsKey(oldName)) {
        throw Exception('Playlist not found');
      }
      if (_playlists.containsKey(newName)) {
        throw Exception('A playlist with this name already exists');
      }

      final songs = _playlists[oldName]!;

      _playlists.remove(oldName);
      _playlists[newName] = songs;

      if (_currentPlaylist == oldName) {
        _currentPlaylist = newName;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error renaming playlist: $e");
      rethrow;
    }
  }
}
