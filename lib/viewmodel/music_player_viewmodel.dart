import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mediaplayer/model/song_model2.dart';
import 'package:mediaplayer/service/audio_service.dart';

class MusicPlayerViewModel extends ChangeNotifier {
  final AudioService _audioService;
  List<SongModel2> _songs = [];
  SongModel2? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isShuffleMode = false;
  get isShuffleMode => _isShuffleMode;

  bool _isRepeatMode = false;
  get isRepeatMode => _isRepeatMode;

  MusicPlayerViewModel(this._audioService) {
    _initializePlayer();
  }

  List<SongModel2> get songs => _songs;
  SongModel2? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  final AudioPlayer _audioPlayer = AudioPlayer();
  get audioPlayer => _audioPlayer;
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;
  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> _initializePlayer() async {
    _audioService.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _audioService.player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _audioService.player.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  Future<void> loadSongs() async {
    _songs = await _audioService.getLocalSongs();
    notifyListeners();
  }

  Future<void> playSong(SongModel2 song) async {
    await _audioService.play(song.filePath);
    _currentSong = song;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioService.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _audioService.resume();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
    notifyListeners();
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
}
