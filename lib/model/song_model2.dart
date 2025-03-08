import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;

class SongModel2 {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration? duration;
  final Uri? artworkUri;

  SongModel2({
    required this.id,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    required this.filePath,
    this.duration,
    this.artworkUri,
  });

  late final AudioSource audioSource;

  factory SongModel2.fromFilePath(String filePath) {
    final fileName = path.basename(filePath);
    final title = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    return SongModel2(
      id: title + filePath,
      filePath: filePath,
      title: title,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: const Duration(
          seconds: 0), // Default duration that will be updated when playing
      artworkUri: null, // Artwork URI will be set when metadata is loaded
    );
  }

  MediaItem get metadata => MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
      );
}
