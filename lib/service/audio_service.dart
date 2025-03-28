import 'dart:developer';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:rxdart/rxdart.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Stream that combines the current position, buffered position, and duration
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  // Current playback state
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Volume
  double get volume => _audioPlayer.volume;
  set volume(double value) => _audioPlayer.setVolume(value);

  // Speed
  double get speed => _audioPlayer.speed;
  set speed(double value) => _audioPlayer.setSpeed(value);

  // Current song duration
  Duration get duration => _audioPlayer.duration ?? Duration.zero;

  // Current position
  Duration get position => _audioPlayer.position;

  // Is playing
  bool get isPlaying => _audioPlayer.playing;

  // Current song index in the playlist
  int? get currentIndex => _audioPlayer.currentIndex;

  // Initialize the service
  Future<void> init() async {
    // Handle audio interruptions (becoming noisy is handled automatically by the plugin)
    await _audioPlayer.setLoopMode(LoopMode.off);
    await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(true);
  }

  // Load a playlist of songs
  Future<void> setPlaylist(List<SongModel> songs,
      {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    try {
      log('Setting playlist with ${songs.length} songs, initial index: $initialIndex');

      // Filter out songs with invalid file paths
      final validSongs = songs.where((song) {
        final songFile = Uri.file(song.filePath).toFilePath();
        final isValid = songFile.isNotEmpty;
        if (!isValid) {
          log('Invalid song file path: ${song.filePath}');
        }
        return isValid;
      }).toList();

      if (validSongs.isEmpty) {
        log('No valid songs in playlist');
        return;
      }

      // Make sure initialIndex is valid for the filtered list
      if (initialIndex >= validSongs.length) {
        initialIndex = 0;
      }

      log('Creating audio source with ${validSongs.length} valid songs');
      final playlist = ConcatenatingAudioSource(
        children: validSongs
            .map(
              (song) => AudioSource.uri(
                Uri.file(song.filePath),
                tag: MediaItem(
                  id: song.id,
                  title: song.title,
                  artist: song.artist,
                  album: song.album,
                  artUri:
                      song.albumArt.isNotEmpty ? Uri.file(song.albumArt) : null,
                  duration: song.duration,
                ),
              ),
            )
            .toList(),
      );

      log('Setting audio source...');
      // Set a timeout for the operation
      await _audioPlayer
          .setAudioSource(playlist, initialIndex: initialIndex)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('Timeout setting audio source');
          throw Exception('Timeout setting audio source');
        },
      );
      log('Audio source set successfully');
    } catch (e) {
      log('Error setting playlist: $e');
      // Just log the error but don't rethrow to prevent crashes
    }
  }

  // Play/pause toggle
  Future<void> playOrPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  // Play
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      log('Error playing: $e');
    }
  }

  // Pause
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      log('Error pausing: $e');
    }
  }

  // Stop
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      log('Error stopping: $e');
    }
  }

  // Skip to next song
  Future<void> next() async {
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      log('Error skipping to next: $e');
    }
  }

  // Skip to previous song
  Future<void> previous() async {
    try {
      if (_audioPlayer.position > const Duration(seconds: 3)) {
        await _audioPlayer.seek(Duration.zero);
      } else {
        await _audioPlayer.seekToPrevious();
      }
    } catch (e) {
      log('Error skipping to previous: $e');
    }
  }

  // Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      log('Error seeking: $e');
    }
  }

  // Seek to a specific index
  Future<void> seekToIndex(int index) async {
    try {
      await _audioPlayer.seek(Duration.zero, index: index);
    } catch (e) {
      log('Error seeking to index: $e');
    }
  }

  // Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await _audioPlayer.setLoopMode(mode);
    } catch (e) {
      log('Error setting loop mode: $e');
    }
  }

  // Set shuffle mode
  Future<void> setShuffleMode(bool enabled) async {
    try {
      await _audioPlayer.setShuffleModeEnabled(enabled);
    } catch (e) {
      log('Error setting shuffle mode: $e');
    }
  }

  // Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
