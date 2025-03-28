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

    final playlist = ConcatenatingAudioSource(
      children: songs
          .map(
            (song) => AudioSource.uri(
              Uri.parse('file://${song.filePath}'),
              tag: MediaItem(
                id: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                artUri: song.albumArt.isNotEmpty
                    ? Uri.parse('file://${song.albumArt}')
                    : null,
                duration: song.duration,
              ),
            ),
          )
          .toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
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
    await _audioPlayer.play();
  }

  // Pause
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // Stop
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Skip to next song
  Future<void> next() async {
    await _audioPlayer.seekToNext();
  }

  // Skip to previous song
  Future<void> previous() async {
    if (_audioPlayer.position > const Duration(seconds: 3)) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      await _audioPlayer.seekToPrevious();
    }
  }

  // Seek to a specific position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Seek to a specific index
  Future<void> seekToIndex(int index) async {
    await _audioPlayer.seek(Duration.zero, index: index);
  }

  // Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
  }

  // Set shuffle mode
  Future<void> setShuffleMode(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  // Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
