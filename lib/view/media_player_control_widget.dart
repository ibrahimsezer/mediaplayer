import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MediaPlayerControlWidget extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final bool isEnabled;

  const MediaPlayerControlWidget({
    super.key,
    required this.audioPlayer,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: audioPlayer.seekToPrevious,
        ),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: isEnabled ? audioPlayer.play : null,
                color: isEnabled ? null : Colors.grey,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: isEnabled ? audioPlayer.pause : null,
                color: isEnabled ? null : Colors.grey,
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: audioPlayer.seekToNext,
        ),
      ],
    );
  }
}
