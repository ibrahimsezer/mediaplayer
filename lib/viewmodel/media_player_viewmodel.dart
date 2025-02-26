import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;

class MediaPlayerViewModel extends ChangeNotifier {
  final List<AudioSource> _songs = [];
  final List<String> _songNames = [];
  final List<MediaItem> _metadata = [];

  get songs => _songs;
  get songNames => _songNames;
  get metadata => _metadata;

  int _currentIndex = 0;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  final ConcatenatingAudioSource _playlist =
      ConcatenatingAudioSource(children: []);

  get isShuffleMode => _isShuffleMode;
  get isRepeatMode => _isRepeatMode;
  get playlist => _playlist;
  int get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  get audioPlayer => _audioPlayer;

  MediaPlayerViewModel() {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _playlist.addAll(_songs);
      await _audioPlayer.setAudioSource(_playlist);
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
          List<AudioSource> newSongs = [];

          // Add new songs and their metadata
          for (String? filePath in result.paths) {
            if (filePath != null) {
              final fileName = path.basename(filePath);
              final title = fileName.contains('.')
                  ? fileName.substring(0, fileName.lastIndexOf('.'))
                  : fileName;

              final mediaItem = MediaItem(
                id: filePath,
                album: "Local Audio",
                title: title,
                artist: "Unknown Artist",
                artUri: null,
              );

              final audioSource = AudioSource.uri(
                Uri.file(filePath),
                tag: mediaItem,
              );

              newSongs.add(audioSource);
              _songs.add(audioSource);
              _songNames.add(title);
              _metadata.add(mediaItem);
            }
          }

          await _playlist.addAll(newSongs);

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

  Future<void> addToPlaylist(String filePath) async {
    try {
      final fileName = path.basename(filePath);
      final title = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      final mediaItem = MediaItem(
        id: filePath,
        album: "Local Audio",
        title: title,
        artist: "Unknown Artist",
        artUri: null,
      );

      final audioSource = AudioSource.uri(
        Uri.file(filePath),
        tag: mediaItem,
      );

      _songs.add(audioSource);
      _songNames.add(title);
      _metadata.add(mediaItem);

      await _playlist.add(audioSource);

      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setAudioSource(_playlist);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error adding to playlist: $e");
      rethrow;
    }
  }

  Future<void> removeFromPlaylist(int index) async {
    try {
      if (index >= 0 && index < _songs.length) {
        await _playlist.removeAt(index);
        _songs.removeAt(index);
        _songNames.removeAt(index);
        _metadata.removeAt(index);

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

        final name = _songNames.removeAt(oldIndex);
        _songNames.insert(newIndex, name);

        final meta = _metadata.removeAt(oldIndex);
        _metadata.insert(newIndex, meta);

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reordering playlist: $e");
      rethrow;
    }
  }
}
