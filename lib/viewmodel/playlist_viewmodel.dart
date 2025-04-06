import 'package:flutter/foundation.dart';
import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:mediaplayer/service/playlist_repository.dart';
import 'package:mediaplayer/service/song_repository.dart';

class PlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _playlistRepository = PlaylistRepository();
  final SongRepository _songRepository = SongRepository();

  // All playlists
  List<PlaylistModel> _playlists = [];
  List<PlaylistModel> get playlists => _playlists;

  // Currently selected playlist
  PlaylistModel? _selectedPlaylist;
  PlaylistModel? get selectedPlaylist => _selectedPlaylist;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String _error = '';
  String get error => _error;
  bool get hasError => _error.isNotEmpty;

  // Constructor
  PlaylistViewModel() {
    loadPlaylists();
  }

  // Load playlists from storage
  Future<void> loadPlaylists() async {
    _setLoading(true);

    try {
      await _playlistRepository.loadPlaylists();
      _playlists = _playlistRepository.getAllPlaylists();
      _clearError();
    } catch (e) {
      _setError('Failed to load playlists: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new playlist
  Future<PlaylistModel?> createPlaylist(String name,
      {String description = '', String coverArt = ''}) async {
    if (name.trim().isEmpty) {
      _setError('Playlist name cannot be empty');
      return null;
    }

    _clearError();

    try {
      final playlist = _playlistRepository.createPlaylist(name,
          description: description, coverArt: coverArt);
      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return playlist;
    } catch (e) {
      _setError('Failed to create playlist: $e');
      return null;
    }
  }

  // Delete a playlist
  Future<bool> deletePlaylist(String id) async {
    if (_selectedPlaylist?.id == id) {
      _selectedPlaylist = null;
    }

    try {
      _playlistRepository.deletePlaylist(id);
      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete playlist: $e');
      return false;
    }
  }

  // Update playlist details
  Future<bool> updatePlaylist(String id,
      {String? name, String? description, String? coverArt}) async {
    try {
      _playlistRepository.updatePlaylist(id,
          name: name, description: description, coverArt: coverArt);

      // Update the selected playlist if it's the one being edited
      if (_selectedPlaylist?.id == id) {
        _selectedPlaylist = _playlistRepository.getPlaylistById(id);
      }

      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update playlist: $e');
      return false;
    }
  }

  // Select a playlist
  void selectPlaylist(String id) {
    _selectedPlaylist = _playlistRepository.getPlaylistById(id);
    notifyListeners();
  }

  // Clear selected playlist
  void clearSelectedPlaylist() {
    _selectedPlaylist = null;
    notifyListeners();
  }

  // Get a playlist by ID
  PlaylistModel? getPlaylistById(String id) {
    return _playlistRepository.getPlaylistById(id);
  }

  // Add a song to the selected playlist
  Future<bool> addSongToSelectedPlaylist(SongModel song) {
    if (_selectedPlaylist == null) {
      _setError('No playlist selected');
      return Future.value(false);
    }

    return addSongToPlaylist(_selectedPlaylist!.id, song);
  }

  // Add a song to a playlist
  Future<bool> addSongToPlaylist(String playlistId, SongModel song) async {
    try {
      _playlistRepository.addSongToPlaylist(playlistId, song);

      // Refresh the selected playlist if it's the one being modified
      if (_selectedPlaylist?.id == playlistId) {
        _selectedPlaylist = _playlistRepository.getPlaylistById(playlistId);
      }

      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add song to playlist: $e');
      return false;
    }
  }

  // Remove a song from the selected playlist
  Future<bool> removeSongFromSelectedPlaylist(String songId) {
    if (_selectedPlaylist == null) {
      _setError('No playlist selected');
      return Future.value(false);
    }

    return removeSongFromPlaylist(_selectedPlaylist!.id, songId);
  }

  // Remove a song from a playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      _playlistRepository.removeSongFromPlaylist(playlistId, songId);

      // Refresh the selected playlist if it's the one being modified
      if (_selectedPlaylist?.id == playlistId) {
        _selectedPlaylist = _playlistRepository.getPlaylistById(playlistId);
      }

      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove song from playlist: $e');
      return false;
    }
  }

  // Reorder songs in the selected playlist
  Future<bool> reorderSongsInSelectedPlaylist(int oldIndex, int newIndex) {
    if (_selectedPlaylist == null) {
      _setError('No playlist selected');
      return Future.value(false);
    }

    return reorderSongsInPlaylist(_selectedPlaylist!.id, oldIndex, newIndex);
  }

  // Reorder songs in a playlist
  Future<bool> reorderSongsInPlaylist(
      String playlistId, int oldIndex, int newIndex) async {
    try {
      _playlistRepository.reorderPlaylistSongs(playlistId, oldIndex, newIndex);

      // Refresh the selected playlist if it's the one being modified
      if (_selectedPlaylist?.id == playlistId) {
        _selectedPlaylist = _playlistRepository.getPlaylistById(playlistId);
      }

      _playlists = _playlistRepository.getAllPlaylists();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reorder songs in playlist: $e');
      return false;
    }
  }

  // Search for playlists
  List<PlaylistModel> searchPlaylists(String query) {
    if (query.isEmpty) return _playlists;
    return _playlistRepository.searchPlaylists(query);
  }

  // Get songs from a playlist
  List<SongModel> getPlaylistSongs(String playlistId) {
    final playlist = _playlistRepository.getPlaylistById(playlistId);
    return playlist?.songs ?? [];
  }

  // Set loading state
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
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
