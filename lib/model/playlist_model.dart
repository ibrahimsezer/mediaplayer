import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String coverArt;
  final List<SongModel> songs;
  final String description;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.coverArt,
    required this.songs,
    this.description = '',
  });

  int get songCount => songs.length;

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (total, song) => total + song.duration,
    );
  }

  // For demo purposes
  static List<PlaylistModel> mockPlaylists = [
    PlaylistModel(
      id: '1',
      name: 'Favorites',
      coverArt: 'lib/assets/images/default_music_photo.png',
      description: 'My favorite tracks',
      songs: SongModel.mockSongs.sublist(0, 3),
    ),
    PlaylistModel(
      id: '2',
      name: 'Workout Mix',
      coverArt: 'lib/assets/images/default_music_photo.png',
      description: 'Energetic tracks for the gym',
      songs: SongModel.mockSongs.sublist(3, 6),
    ),
    PlaylistModel(
      id: '3',
      name: 'Chill Vibes',
      coverArt: 'lib/assets/images/default_music_photo.png',
      description: 'Relaxing music for unwinding',
      songs: SongModel.mockSongs.sublist(1, 5),
    ),
    PlaylistModel(
      id: '4',
      name: 'Road Trip',
      coverArt: 'lib/assets/images/default_music_photo.png',
      description: 'Perfect for long drives',
      songs: SongModel.mockSongs.sublist(2, 7),
    ),
  ];
}
