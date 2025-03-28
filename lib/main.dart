import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mediaplayer/const/app_constants.dart';
import 'package:mediaplayer/view/player_view.dart';
import 'package:mediaplayer/viewmodel/audio_player_viewmodel.dart';
import 'package:mediaplayer/viewmodel/library_viewmodel.dart';
import 'package:mediaplayer/viewmodel/playlist_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:mediaplayer/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.mediaplayer.channel.audio',
    androidNotificationChannelName: 'Media Player Audio Service',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerViewModel()),
        ChangeNotifierProvider(create: (_) => LibraryViewModel()),
        ChangeNotifierProvider(create: (_) => PlaylistViewModel()),
      ],
      child: const MusicPlayerApp(),
    ),
  );
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the AudioPlayerViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioPlayerViewModel>(context, listen: false).init();
    });

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: themeProvider.currentTheme,
          home: const PlayerView(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
