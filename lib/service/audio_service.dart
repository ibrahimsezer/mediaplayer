import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mediaplayer/model/song_model2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;

class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<void> play(String filePath) async {
    final audioSource = AudioSource.uri(Uri.parse(filePath),
        tag: MediaItem(
            id: filePath,
            title: path.basename(filePath),
            artist: 'Unknown Artist',
            album: 'Unknown Album'));
    await player.setAudioSource(audioSource);
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<List<SongModel2>> getLocalSongs() async {
    try {
      // Request storage permissions
      final storageStatus = await Permission.storage.request();
      final audioStatus = await Permission.audio.request();

      if (storageStatus.isGranted || audioStatus.isGranted) {
        // Use FilePicker to let user select audio files
        final result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );

        if (result != null && result.paths.isNotEmpty) {
          List<SongModel2> songs = [];

          // Process each selected file
          for (String? filePath in result.paths) {
            if (filePath != null) {
              // Create a SongModel from the file path
              final songModel = SongModel2.fromFilePath(filePath);
              // Create MediaItem tag for the audio source
              songModel.audioSource = AudioSource.uri(Uri.parse(filePath),
                  tag: MediaItem(
                      id: filePath,
                      title: path.basename(filePath),
                      artist: 'Unknown Artist',
                      album: 'Unknown Album'));
              songs.add(songModel);
            }
          }

          return songs;
        }
      }

      return [];
    } catch (e) {
      print('Error scanning songs: $e');
      return [];
    }
  }
}
