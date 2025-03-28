class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumArt;
  final Duration duration;
  final String filePath;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArt,
    required this.duration,
    required this.filePath,
  });

  // For demo purposes
  static List<SongModel> mockSongs = [
    SongModel(
      id: '1',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 3, seconds: 20),
      filePath: '',
    ),
    SongModel(
      id: '2',
      title: 'Watermelon Sugar',
      artist: 'Harry Styles',
      album: 'Fine Line',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 2, seconds: 54),
      filePath: '',
    ),
    SongModel(
      id: '3',
      title: 'Don\'t Start Now',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 3, seconds: 3),
      filePath: '',
    ),
    SongModel(
      id: '4',
      title: 'Mood',
      artist: '24kGoldn ft. Iann Dior',
      album: 'El Dorado',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 2, seconds: 21),
      filePath: '',
    ),
    SongModel(
      id: '5',
      title: 'Levitating',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 3, seconds: 23),
      filePath: '',
    ),
    SongModel(
      id: '6',
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      album: 'After Hours',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 3, seconds: 35),
      filePath: '',
    ),
    SongModel(
      id: '7',
      title: 'Peaches',
      artist: 'Justin Bieber ft. Daniel Caesar, Giveon',
      album: 'Justice',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 3, seconds: 18),
      filePath: '',
    ),
    SongModel(
      id: '8',
      title: 'Stay',
      artist: 'The Kid LAROI, Justin Bieber',
      album: 'F*CK LOVE 3: OVER YOU',
      albumArt: 'lib/assets/images/default_music_photo.png',
      duration: const Duration(minutes: 2, seconds: 21),
      filePath: '',
    ),
  ];
}
