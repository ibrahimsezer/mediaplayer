import 'package:flutter/material.dart';
import 'package:mediaplayer/media_player.dart';
import 'package:mediaplayer/slide_page_action.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Song $index"),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SlidePageAction(
                pageName: MediaPlayer(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
