import 'dart:developer';

import 'package:mediaplayer/model/playlist_model.dart';
import 'package:mediaplayer/model/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlaylistRepository {
  // In-memory cache of playlists
  List<PlaylistModel> _playlists = [];

  // Get all playlists
  List<PlaylistModel> getAllPlaylists() {
    return _playlists;
  }

  // Get a playlist by id
  PlaylistModel? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create a new playlist
  PlaylistModel createPlaylist(String name,
      {String description = '', String coverArt = ''}) {
    // Generate a unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Set a default cover art if none provided
    final finalCoverArt = coverArt.isNotEmpty
        ? coverArt
        : 'lib/assets/images/default_music_photo.png';

    final playlist = PlaylistModel(
      id: id,
      name: name,
      description: description,
      coverArt: finalCoverArt,
      songs: [],
    );

    _playlists.add(playlist);
    _savePlaylists();

    return playlist;
  }

  // Update playlist metadata
  void updatePlaylist(String id,
      {String? name, String? description, String? coverArt}) {
    final index = _playlists.indexWhere((playlist) => playlist.id == id);

    if (index >= 0) {
      final playlist = _playlists[index];

      _playlists[index] = PlaylistModel(
        id: playlist.id,
        name: name ?? playlist.name,
        description: description ?? playlist.description,
        coverArt: coverArt ?? playlist.coverArt,
        songs: playlist.songs,
      );

      _savePlaylists();
    }
  }

  // Delete a playlist
  void deletePlaylist(String id) {
    _playlists.removeWhere((playlist) => playlist.id == id);
    _savePlaylists();
  }

  // Add a song to a playlist
  void addSongToPlaylist(String playlistId, SongModel song) {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);

    if (index >= 0) {
      final playlist = _playlists[index];

      // Check if song already exists in playlist
      if (!playlist.songs.any((s) => s.id == song.id)) {
        final updatedSongs = List<SongModel>.from(playlist.songs)..add(song);

        _playlists[index] = PlaylistModel(
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          coverArt: playlist.coverArt,
          songs: updatedSongs,
        );

        _savePlaylists();
      }
    }
  }

  // Remove a song from a playlist
  void removeSongFromPlaylist(String playlistId, String songId) {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);

    if (index >= 0) {
      final playlist = _playlists[index];
      final updatedSongs =
          playlist.songs.where((song) => song.id != songId).toList();

      _playlists[index] = PlaylistModel(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        coverArt: playlist.coverArt,
        songs: updatedSongs,
      );

      _savePlaylists();
    }
  }

  // Reorder songs in a playlist
  void reorderPlaylistSongs(String playlistId, int oldIndex, int newIndex) {
    final index =
        _playlists.indexWhere((playlist) => playlist.id == playlistId);

    if (index >= 0) {
      final playlist = _playlists[index];
      final updatedSongs = List<SongModel>.from(playlist.songs);

      // Handle reordering
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = updatedSongs.removeAt(oldIndex);
      updatedSongs.insert(newIndex, item);

      _playlists[index] = PlaylistModel(
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        coverArt: playlist.coverArt,
        songs: updatedSongs,
      );

      _savePlaylists();
    }
  }

  // Load playlists from shared preferences
  Future<void> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getStringList('playlists') ?? [];

      _playlists = playlistsJson
          .map((json) => _decodePlaylist(json))
          .whereType<PlaylistModel>() // Filter out nulls
          .toList();
    } catch (e) {
      log('Error loading playlists: $e');
    }
  }

  // Save playlists to shared preferences
  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson =
          _playlists.map((playlist) => _encodePlaylist(playlist)).toList();
      await prefs.setStringList('playlists', playlistsJson);
    } catch (e) {
      log('Error saving playlists: $e');
    }
  }

  // Encode a playlist to JSON
  String _encodePlaylist(PlaylistModel playlist) {
    // Encode songs to JSON
    final songsJson = playlist.songs
        .map((song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist,
              'album': song.album,
              'albumArt': song.albumArt,
              'duration': song.duration.inMilliseconds,
              'filePath': song.filePath,
            })
        .toList();

    // Encode playlist with songs
    return jsonEncode({
      'id': playlist.id,
      'name': playlist.name,
      'description': playlist.description,
      'coverArt': playlist.coverArt,
      'songs': songsJson,
    });
  }

  // Decode a playlist from JSON
  PlaylistModel? _decodePlaylist(String playlistJson) {
    try {
      final Map<String, dynamic> map = jsonDecode(playlistJson);

      // Decode songs from JSON
      final List<dynamic> songsJson = map['songs'];
      final List<SongModel> songs = songsJson
          .map((songMap) => SongModel(
                id: songMap['id'],
                title: songMap['title'],
                artist: songMap['artist'],
                album: songMap['album'],
                albumArt: songMap['albumArt'],
                duration: Duration(milliseconds: songMap['duration']),
                filePath: songMap['filePath'],
              ))
          .toList();

      // Create playlist
      return PlaylistModel(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        coverArt: map['coverArt'],
        songs: songs,
      );
    } catch (e) {
      log('Error decoding playlist: $e');
      return null;
    }
  }

  // Search playlists
  List<PlaylistModel> searchPlaylists(String query) {
    final lowerQuery = query.toLowerCase();
    return _playlists
        .where((playlist) =>
            playlist.name.toLowerCase().contains(lowerQuery) ||
            playlist.description.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
