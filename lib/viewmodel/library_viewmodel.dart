import 'package:flutter/foundation.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/service/file_scanner_service.dart';
import 'package:mediaplayer/service/song_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final FileScannerService _scannerService = FileScannerService();
  final SongRepository _songRepository = SongRepository();

  // All songs
  List<SongModel> _allSongs = [];
  List<SongModel> get allSongs => _allSongs;

  // All albums
  List<String> _allAlbums = [];
  List<String> get allAlbums => _allAlbums;

  // All artists
  List<String> _allArtists = [];
  List<String> get allArtists => _allArtists;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state
  String _error = '';
  String get error => _error;
  bool get hasError => _error.isNotEmpty;

  // Constructor
  LibraryViewModel() {
    _loadSavedSongs();
  }

  // Load saved songs from local storage
  Future<void> _loadSavedSongs() async {
    _setLoading(true);

    try {
      await _songRepository.loadSongs();
      _refreshLibraryData();
      _clearError();
    } catch (e) {
      _setError('Failed to load saved songs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Request permissions and scan for music
  Future<bool> requestPermissionsAndScan() async {
    final hasPermission = await _scannerService.requestPermissions();
    if (hasPermission) {
      return true;
    } else {
      _setError(
          'Permission denied. Please grant storage permission to scan for music.');
      return false;
    }
  }

  // Scan a directory for music
  Future<void> scanDirectory(String directoryPath) async {
    _setLoading(true);
    _clearError();

    try {
      final songs = await _scannerService.scanDirectory(directoryPath);
      if (songs.isEmpty) {
        _setError('No music files found in this directory.');
      } else {
        _songRepository.addSongs(songs);
        _refreshLibraryData();
      }
    } catch (e) {
      _setError('Error scanning directory: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Pick and scan a directory
  Future<void> pickAndScanDirectory() async {
    final hasPermission = await requestPermissionsAndScan();
    if (!hasPermission) return;

    final directoryPath = await _scannerService.pickDirectory();

    if (directoryPath != null) {
      await scanDirectory(directoryPath);
    }
  }

  // Pick and add music files
  Future<void> pickAndAddMusicFiles() async {
    final hasPermission = await requestPermissionsAndScan();
    if (!hasPermission) return;

    _setLoading(true);
    _clearError();

    try {
      final filePaths = await _scannerService.pickAudioFiles();

      if (filePaths.isEmpty) {
        // User canceled or didn't select any files
        return;
      }

      final songs = <SongModel>[];

      for (final path in filePaths) {
        final song = await _scannerService.extractMetadata(path);
        if (song != null) {
          songs.add(song);
        }
      }

      if (songs.isEmpty) {
        _setError('No valid music files were selected.');
      } else {
        _songRepository.addSongs(songs);
        _refreshLibraryData();
      }
    } catch (e) {
      _setError('Error adding music files: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get songs by album
  List<SongModel> getSongsByAlbum(String album) {
    return _songRepository.getSongsByAlbum(album);
  }

  // Get songs by artist
  List<SongModel> getSongsByArtist(String artist) {
    return _songRepository.getSongsByArtist(artist);
  }

  // Search for songs, albums, and artists
  List<SongModel> searchLibrary(String query) {
    if (query.isEmpty) return [];
    return _songRepository.searchSongs(query);
  }

  // Refresh library data
  void _refreshLibraryData() {
    _allSongs = _songRepository.getAllSongs();
    _allAlbums = _songRepository.getAllAlbums();
    _allArtists = _songRepository.getAllArtists();
    notifyListeners();
  }

  // Clear all songs
  Future<void> clearLibrary() async {
    _setLoading(true);

    try {
      _songRepository.clearSongs();
      _refreshLibraryData();
      _clearError();
    } catch (e) {
      _setError('Failed to clear library: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = '';
    notifyListeners();
  }
}
