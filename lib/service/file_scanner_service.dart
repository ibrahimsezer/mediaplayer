import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/model/song_model.dart';

class FileScannerService {
  static const List<String> _supportedExtensions = [
    '.mp3',
    '.m4a',
    '.wav',
    '.aac',
    '.ogg',
    '.flac'
  ];

  // Request storage permissions
  Future<bool> requestPermissions() async {
    // For Android 13+ we need to request specific permissions
    if (Platform.isAndroid) {
      final status = await Permission.audio.request();
      if (status.isGranted) {
        return true;
      }

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }

    return true;
  }

  // Scan a directory for audio files
  Future<List<SongModel>> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<SongModel> songs = [];

    if (!await directory.exists()) {
      return songs;
    }

    try {
      final List<FileSystemEntity> entities =
          await directory.list(recursive: true).toList();

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();

          if (_supportedExtensions.any((ext) => path.endsWith(ext))) {
            final song = await extractMetadata(entity.path);
            if (song != null) {
              songs.add(song);
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning directory: $e');
    }

    return songs;
  }

  // Pick a directory to scan
  Future<String?> pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    return result;
  }

  // Pick audio files
  Future<List<String>> pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => path!)
          .toList();
    }

    return [];
  }

  // Extract metadata from an audio file using just_audio
  Future<SongModel?> extractMetadata(String filePath) async {
    final audioPlayer = AudioPlayer();

    try {
      // Load the file to extract metadata
      final duration = await audioPlayer.setFilePath(filePath);

      // Get file name for title if metadata not available
      final title = _extractTitleFromPath(filePath);

      // Default values since we don't have full metadata
      const artist = 'Unknown Artist';
      const album = 'Unknown Album';

      // Use default album art
      const albumArt = 'lib/assets/images/default_music_photo.png';

      await audioPlayer.dispose();

      return SongModel(
        id: filePath.hashCode.toString(),
        title: title,
        artist: artist,
        album: album,
        albumArt: albumArt,
        duration: duration ?? Duration.zero,
        filePath: filePath,
      );
    } catch (e) {
      await audioPlayer.dispose();
      print('Error extracting metadata from $filePath: $e');
      return null;
    }
  }

  // Extract title from file path if metadata is missing
  String _extractTitleFromPath(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;

    // Remove the extension
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1) {
      return fileName.substring(0, lastDotIndex);
    }

    return fileName;
  }
}
