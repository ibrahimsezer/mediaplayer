import 'package:flutter/material.dart';
import 'package:mediaplayer/media_player.dart';
import 'package:mediaplayer/slide_page_action.dart';
import 'package:provider/provider.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  Future<void> _playSong(int index) async {
    final _mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);
    await _mediaPlayer.audioPlayer.seek(Duration.zero, index: index);
    _mediaPlayer.audioPlayer.play();
    _mediaPlayer.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ListView.builder(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(mediaPlayer.songs[index].tag?.toString() ??
                      'Song $index'),
                  onTap: () => _playSong(index),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SlidePageAction(
                pageName: MediaPlayerView(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
