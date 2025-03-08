import 'package:flutter/material.dart';
import 'package:mediaplayer/const/const.dart';
import 'package:mediaplayer/service/audio_service.dart';
import 'package:mediaplayer/view/music_player_view.dart';
import 'package:mediaplayer/viewmodel/music_player_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.mediaplayer.channel.audio',
    androidNotificationChannelName: 'Media Player',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MediaPlayerViewModel()),
        Provider<AudioService>(create: (_) => AudioService()),
        ChangeNotifierProvider<MusicPlayerViewModel>(
            create: (context) => MusicPlayerViewModel(
                Provider.of<AudioService>(context, listen: false))),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: ConstTexts.jswMediaPlayer,
          theme: themeProvider.currentTheme,
          home: MusicPlayerView(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
