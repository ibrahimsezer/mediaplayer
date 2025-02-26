import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';

class MediaPlayerViewModel extends ChangeNotifier {
  late AudioHandler _audioHandler;
  List<AudioSource> _songs = [];
  get songs => _songs;

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
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.example.mediaplayer.channel.audio',
        androidNotificationChannelName: 'Media Player',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        notificationColor: Colors.blue,
        androidShowNotificationBadge: true,
        artDownscaleWidth: 300,
        artDownscaleHeight: 300,
      ),
    );
    await _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _playlist.addAll(_songs);
    await _audioPlayer.setAudioSource(_playlist);
    await _audioPlayer.setLoopMode(LoopMode.off);

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      _updatePlaybackState(playerState);
    });

    // Listen to current song changes
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        _currentIndex = index;
        _updateMediaItem();
        notifyListeners();
      }
    });
  }

  void _updatePlaybackState(PlayerState playerState) {
    final playing = playerState.playing;
    final processingState = playerState.processingState;

    AudioProcessingState audioProcessingState;
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      audioProcessingState = AudioProcessingState.buffering;
    } else if (processingState == ProcessingState.ready) {
      audioProcessingState = AudioProcessingState.ready;
    } else if (processingState == ProcessingState.completed) {
      audioProcessingState = AudioProcessingState.completed;
    } else {
      audioProcessingState = AudioProcessingState.idle;
    }

    final newState = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: audioProcessingState,
      playing: playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );

    (_audioHandler as BaseAudioHandler).playbackState.add(newState);
  }

  void _updateMediaItem() {
    if (_currentIndex >= 0 && _currentIndex < _songs.length) {
      final mediaItem = MediaItem(
        id: _currentIndex.toString(),
        album: "Unknown Album",
        title: "Song ${_currentIndex + 1}",
        artist: "Unknown Artist",
      );
      (_audioHandler as BaseAudioHandler).mediaItem.add(mediaItem);
    }
  }

  Future<void> _loadLocalSongs() async {
    if (_audioHandler == null) {
      await _initializeAudioService();
    }

    try {
      // Request both storage permissions for better compatibility
      final storageStatus = await Permission.storage.request();
      final audioStatus = await Permission.audio.request();

      if (storageStatus.isGranted || audioStatus.isGranted) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );

        if (result != null && result.paths.isNotEmpty) {
          // Clear existing songs and playlist
          _songs.clear();
          await _playlist.clear();

          // Add new songs
          _songs = result.paths
              .where((path) => path != null)
              .map((path) => AudioSource.file(path!))
              .toList();

          // Add songs to playlist
          await _playlist.addAll(_songs);

          // Set the audio source if it's the first time
          if (_audioPlayer.audioSource == null) {
            await _audioPlayer.setAudioSource(_playlist);
          }

          _updateMediaItem();
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

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  @override
  Future<void> play() async {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToPrevious,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: AudioProcessingState.ready,
      playing: true,
    ));
  }

  @override
  Future<void> pause() async {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToPrevious,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));
  }

  @override
  Future<void> stop() async {
    playbackState.add(PlaybackState(
      controls: [],
      systemActions: const {},
      androidCompactActionIndices: const [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }
}
