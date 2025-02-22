import 'package:flutter/material.dart';
import 'package:mediaplayer/theme/app_theme.dart';
import 'package:mediaplayer/view/media_player_view.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:mediaplayer/helper/slide_page_action.dart';
import 'package:provider/provider.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  Future<void> _playSong(int index) async {
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);
    await mediaPlayer.audioPlayer.seek(Duration.zero, index: index);
    mediaPlayer.audioPlayer.play();
    mediaPlayer.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    final mediaPlayer =
        Provider.of<MediaPlayerViewModel>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.add),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: mediaPlayer.songs.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(mediaPlayer.songs[index].tag?.toString() ??
                          'Song $index'),
                      leading: Icon(Icons.music_note),
                      onTap: () => _playSong(index),
                    );
                  },
                ),
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
      ),
    );
  }
}
