import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:path/path.dart' as path;

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
      // Request both audio and external storage permissions
      final audioStatus = await Permission.audio.request();
      final storageStatus = await Permission.storage.request();
      final externalStorageStatus =
          await Permission.manageExternalStorage.request();

      log('Permission statuses - Audio: $audioStatus, Storage: $storageStatus, External: $externalStorageStatus');

      // Check if any permission is granted
      return audioStatus.isGranted ||
          storageStatus.isGranted ||
          externalStorageStatus.isGranted;
    }

    return true;
  }

  // Scan a directory for audio files
  Future<List<SongModel>> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<SongModel> songs = [];

    if (!await directory.exists()) {
      log('Directory does not exist: $directoryPath');
      return songs;
    }

    try {
      log('Scanning directory: $directoryPath');
      final List<FileSystemEntity> entities =
          await directory.list(recursive: true).toList();

      log('Found ${entities.length} files/directories in total');
      int audioFilesCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path.toLowerCase();

          if (_supportedExtensions.any((ext) => path.endsWith(ext))) {
            audioFilesCount++;
            log('Processing audio file: ${entity.path}');

            try {
              final song = await extractMetadata(entity.path);
              if (song != null) {
                songs.add(song);
                log('Successfully extracted metadata for: ${entity.path}');
              } else {
                log('Failed to extract metadata for: ${entity.path}');
              }
            } catch (e) {
              log('Error processing audio file ${entity.path}: $e');
            }
          }
        }
      }

      log('Found $audioFilesCount audio files, successfully processed ${songs.length}');
    } catch (e) {
      log('Error scanning directory: $e');
    }

    return songs;
  }

  // Pick a directory to scan
  Future<String?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        log('Selected directory: $result');
      } else {
        log('No directory selected');
      }
      return result;
    } catch (e) {
      log('Error picking directory: $e');
      return null;
    }
  }

  // Pick audio files
  Future<List<String>> pickAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        final paths = result.paths
            .where((path) => path != null)
            .map((path) => path!)
            .toList();

        log('Selected ${paths.length} audio files');
        for (var path in paths) {
          log('Selected file: $path');
        }

        return paths;
      } else {
        log('No files selected');
      }
    } catch (e) {
      log('Error picking audio files: $e');
    }

    return [];
  }

  // Extract metadata from an audio file using just_audio
  Future<SongModel?> extractMetadata(String filePath) async {
    final audioPlayer = AudioPlayer();

    try {
      log('Attempting to extract metadata from: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        log('File does not exist: $filePath');
        return null;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        log('File is empty: $filePath');
        return null;
      }

      log('File exists and size is $fileSize bytes');

      // Load the file to extract metadata
      final duration = await audioPlayer.setFilePath(filePath);
      if (duration == null) {
        log('Failed to get duration for: $filePath');
      } else {
        log('Duration: ${duration.inSeconds} seconds');
      }

      // Extract the filename and use it as title if metadata is not available
      final fileName = path.basename(filePath);
      final title = _extractTitleFromPath(filePath);

      log('Extracted title: $title');

      // Default values since we don't have full metadata
      final artist = audioPlayer.sequenceState?.currentSource?.tag?.artist ??
          'Unknown Artist';
      final album = audioPlayer.sequenceState?.currentSource?.tag?.album ??
          'Unknown Album';

      // Use default album art
      const albumArt = 'lib/assets/images/default_music_photo.png';

      await audioPlayer.dispose();

      final song = SongModel(
        id: filePath.hashCode.toString(),
        title: title,
        artist: artist,
        album: album,
        albumArt: albumArt,
        duration: duration ?? Duration.zero,
        filePath: filePath,
      );

      log('Created song model: $song');
      return song;
    } catch (e) {
      await audioPlayer.dispose();
      log('Error extracting metadata from $filePath: $e');

      // Creating a fallback song with basic info in case of error
      try {
        final title = _extractTitleFromPath(filePath);
        return SongModel(
          id: filePath.hashCode.toString(),
          title: title,
          artist: 'Unknown Artist',
          album: 'Unknown Album',
          albumArt: 'lib/assets/images/default_music_photo.png',
          duration: Duration.zero,
          filePath: filePath,
        );
      } catch (fallbackError) {
        log('Error creating fallback song: $fallbackError');
        return null;
      }
    }
  }

  // Extract title from file path if metadata is missing
  String _extractTitleFromPath(String filePath) {
    final fileName = path.basename(filePath);

    // Remove the extension
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1) {
      return fileName.substring(0, lastDotIndex);
    }

    return fileName;
  }
}
