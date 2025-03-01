import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class SongModel {
  final AudioSource audioSource;
  final String title;
  final String artist;
  final String album;
  final String filePath;

  SongModel({
    required this.audioSource,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
  });

  MediaItem get metadata => MediaItem(
        id: filePath,
        album: album,
        title: title,
        artist: artist,
        artUri: null,
      );
}
