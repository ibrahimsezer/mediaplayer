import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPlayerViewModel extends ChangeNotifier {
  List<AudioSource> _songs = [
    AudioSource.uri(Uri.parse(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3')),
    AudioSource.uri(Uri.parse(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3')),
    AudioSource.uri(Uri.parse(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3')),
  ];
  get songs => _songs;

  int _currentIndex = 0;
  bool _isShuffleMode = false;
  bool _isRepeatMode = false;
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  get isShuffleMode => _isShuffleMode;
  get isRepeatMode => _isRepeatMode;
  get playlist => _playlist;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  get audioPlayer => _audioPlayer;

  MediaPlayerViewModel() {
    _initializePlayer();
  }

  void _initializePlayer() {
    _playlist.addAll(_songs);
    _audioPlayer.setAudioSource(_playlist);
    _audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> _loadLocalSongs() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (files != null && files.paths.isNotEmpty) {
        _songs = files.paths
            .where((path) => path != null)
            .map((path) => AudioSource.file(path!))
            .toList();

        await _audioPlayer
            .setAudioSource(ConcatenatingAudioSource(children: _songs));
        notifyListeners();
      }
    }
  }

  get loadLocalSongs => _loadLocalSongs();

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
    final audioSource = AudioSource.file(filePath);
    await _playlist.add(audioSource);
    notifyListeners();
  }

  Future<void> removeFromPlaylist(int index) async {
    await _playlist.removeAt(index);
    notifyListeners();
  }

  Future<void> reorderPlaylist(int oldIndex, int newIndex) async {
    await _playlist.move(oldIndex, newIndex);
    notifyListeners();
  }
}
