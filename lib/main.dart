import 'package:flutter/material.dart';
import 'package:mediaplayer/const/const.dart';
import 'package:mediaplayer/view/media_player_view.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/theme/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: ConstTexts.jswMediaPlayer,
            theme: themeProvider.currentTheme,
            home: const MediaPlayerView(),
          );
        },
      ),
    );
  }
}
