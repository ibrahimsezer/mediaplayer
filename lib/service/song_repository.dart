import 'package:mediaplayer/model/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SongRepository {
  // In-memory cache of songs
  List<SongModel> _songs = [];

  // Get all songs
  List<SongModel> getAllSongs() {
    return _songs;
  }

  // Get a song by id
  SongModel? getSongById(String id) {
    try {
      return _songs.firstWhere((song) => song.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add songs to the repository
  void addSongs(List<SongModel> songs) {
    // Remove duplicates by file path
    final existingPaths = _songs.map((s) => s.filePath).toSet();
    final newSongs =
        songs.where((s) => !existingPaths.contains(s.filePath)).toList();

    _songs.addAll(newSongs);
    _saveSongList();
  }

  // Update song data
  void updateSong(SongModel updatedSong) {
    final index = _songs.indexWhere((song) => song.id == updatedSong.id);
    if (index >= 0) {
      _songs[index] = updatedSong;
      _saveSongList();
    }
  }

  // Remove a song
  void removeSong(String id) {
    _songs.removeWhere((song) => song.id == id);
    _saveSongList();
  }

  // Clear all songs
  void clearSongs() {
    _songs.clear();
    _saveSongList();
  }

  // Load songs from shared preferences
  Future<void> loadSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = prefs.getStringList('songs') ?? [];

      _songs = songsJson
          .map((json) => _decodeSong(json))
          .whereType<SongModel>() // Filter out nulls
          .toList();
    } catch (e) {
      print('Error loading songs: $e');
      // Keep using the current in-memory songs
    }
  }

  // Save songs to shared preferences
  Future<void> _saveSongList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> songsJson =
          _songs.map((song) => _encodeSong(song)).toList();
      await prefs.setStringList('songs', songsJson);
    } catch (e) {
      print('Error saving songs: $e');
    }
  }

  // Encode a song to JSON
  String _encodeSong(SongModel song) {
    return jsonEncode({
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'albumArt': song.albumArt,
      'duration': song.duration.inMilliseconds,
      'filePath': song.filePath,
    });
  }

  // Decode a song from JSON
  SongModel? _decodeSong(String songJson) {
    try {
      final Map<String, dynamic> map = jsonDecode(songJson);
      return SongModel(
        id: map['id'],
        title: map['title'],
        artist: map['artist'],
        album: map['album'],
        albumArt: map['albumArt'],
        duration: Duration(milliseconds: map['duration']),
        filePath: map['filePath'],
      );
    } catch (e) {
      print('Error decoding song: $e');
      return null;
    }
  }

  // Get songs by album
  List<SongModel> getSongsByAlbum(String album) {
    return _songs.where((song) => song.album == album).toList();
  }

  // Get songs by artist
  List<SongModel> getSongsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }

  // Get all albums
  List<String> getAllAlbums() {
    return _songs.map((song) => song.album).toSet().toList();
  }

  // Get all artists
  List<String> getAllArtists() {
    return _songs.map((song) => song.artist).toSet().toList();
  }

  // Search songs
  List<SongModel> searchSongs(String query) {
    final lowerQuery = query.toLowerCase();
    return _songs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
