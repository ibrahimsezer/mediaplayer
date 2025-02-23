import 'package:flutter/material.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () async {
                    final mediaPlayer = Provider.of<MediaPlayerViewModel>(
                        context,
                        listen: false);
                    await mediaPlayer.loadLocalSongs;
                  },
                  icon: Icon(Icons.add),
                ),
              ),
              Expanded(
                child: Consumer<MediaPlayerViewModel>(
                  builder: (context, mediaPlayer, _) {
                    return ReorderableListView.builder(
                      itemCount: mediaPlayer.playlist.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onReorder: mediaPlayer.reorderPlaylist,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: ValueKey(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 16.0),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              mediaPlayer.removeFromPlaylist(index),
                          child: ListTile(
                            title: Text('Song ${index + 1}'),
                            leading: Icon(Icons.music_note),
                            trailing: Icon(Icons.drag_handle),
                            onTap: () => _playSong(index),
                          ),
                        );
                      },
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
