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

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  get audioPlayer => _audioPlayer;

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
}
