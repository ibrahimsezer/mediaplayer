import 'package:flutter/foundation.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/service/file_scanner_service.dart';
import 'package:mediaplayer/service/song_repository.dart';
import 'dart:io';

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
      print('Permissions granted for file scanning');
      return true;
    } else {
      print('Permission denied for file scanning');
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
      print('Starting directory scan: $directoryPath');

      // Check if directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        _setError('Directory does not exist: $directoryPath');
        _setLoading(false);
        return;
      }

      final songs = await _scannerService.scanDirectory(directoryPath);
      print('Scan complete. Found ${songs.length} songs.');

      if (songs.isEmpty) {
        _setError('No music files found in this directory: $directoryPath');
      } else {
        print('Adding ${songs.length} songs to repository');
        _songRepository.addSongs(songs);
        _refreshLibraryData();
        print(
            'Library data refreshed. Now has ${_allSongs.length} songs total.');
      }
    } catch (e) {
      print('Error scanning directory: $e');
      _setError('Error scanning directory: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Pick and scan a directory
  Future<void> pickAndScanDirectory() async {
    final hasPermission = await requestPermissionsAndScan();
    if (!hasPermission) {
      print('No permission to scan directory');
      return;
    }

    final directoryPath = await _scannerService.pickDirectory();

    if (directoryPath != null && directoryPath.isNotEmpty) {
      print('Directory selected for scanning: $directoryPath');
      await scanDirectory(directoryPath);
    } else {
      print('No directory selected or directory path is empty');
      _setError('No directory selected');
    }
  }

  // Pick and add music files
  Future<void> pickAndAddMusicFiles() async {
    final hasPermission = await requestPermissionsAndScan();
    if (!hasPermission) {
      print('No permission to pick music files');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      print('Starting file picking process');
      final filePaths = await _scannerService.pickAudioFiles();

      if (filePaths.isEmpty) {
        print('No files selected or file picking canceled');
        _setError('No files selected');
        _setLoading(false);
        return;
      }

      print('Processing ${filePaths.length} selected files');
      final songs = <SongModel>[];
      final failedFiles = <String>[];

      for (final path in filePaths) {
        try {
          print('Extracting metadata for: $path');
          final song = await _scannerService.extractMetadata(path);
          if (song != null) {
            songs.add(song);
            print('Successfully processed: $path');
          } else {
            failedFiles.add(path);
            print('Failed to extract metadata for: $path');
          }
        } catch (e) {
          failedFiles.add(path);
          print('Error processing file $path: $e');
        }
      }

      if (songs.isEmpty) {
        if (failedFiles.isNotEmpty) {
          _setError(
              'Failed to process all selected files. Check file formats or permissions.');
          print('Failed files: ${failedFiles.join(', ')}');
        } else {
          _setError('No valid music files were selected.');
        }
      } else {
        print('Adding ${songs.length} processed songs to repository');
        _songRepository.addSongs(songs);
        _refreshLibraryData();

        if (failedFiles.isNotEmpty) {
          _setError(
              'Added ${songs.length} songs, but ${failedFiles.length} files could not be processed.');
        }
      }
    } catch (e) {
      print('Error adding music files: $e');
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

    print(
        'Library refreshed: ${_allSongs.length} songs, ${_allAlbums.length} albums, ${_allArtists.length} artists');
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
    print('LibraryViewModel error: $error');
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = '';
    notifyListeners();
  }
}
