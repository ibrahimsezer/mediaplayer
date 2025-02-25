import 'package:flutter/material.dart';
import 'package:mediaplayer/theme/theme_provider.dart';
import 'package:mediaplayer/viewmodel/media_player_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SharedPreferences _prefs;
  bool _crossfadeEnabled = false;
  double _crossfadeDuration = 2.0;
  bool _gaplessPlayback = true;
  bool _showNotification = true;
  bool _saveLastPosition = true;
  String _audioQuality = 'High';
  bool _autoPlay = true;
  String _defaultView = 'Player';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _crossfadeEnabled = _prefs.getBool('crossfadeEnabled') ?? false;
      _crossfadeDuration = _prefs.getDouble('crossfadeDuration') ?? 2.0;
      _gaplessPlayback = _prefs.getBool('gaplessPlayback') ?? true;
      _showNotification = _prefs.getBool('showNotification') ?? true;
      _saveLastPosition = _prefs.getBool('saveLastPosition') ?? true;
      _audioQuality = _prefs.getString('audioQuality') ?? 'High';
      _autoPlay = _prefs.getBool('autoPlay') ?? true;
      _defaultView = _prefs.getString('defaultView') ?? 'Player';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildThemeSection(),
          _buildDivider(),
          _buildPlaybackSection(),
          _buildDivider(),
          _buildAudioSection(),
          _buildDivider(),
          _buildNotificationSection(),
          _buildDivider(),
          _buildStorageSection(),
          _buildDivider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1);
  }

  Widget _buildThemeSection() {
    return _buildSection(
      'Appearance',
      [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Enable dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
        ),
        ListTile(
          title: Text('Default View'),
          subtitle: Text(_defaultView),
          trailing: DropdownButton<String>(
            value: _defaultView,
            items: ['Player', 'Playlist', 'Library'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _defaultView = newValue;
                  _saveSetting('defaultView', newValue);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackSection() {
    return _buildSection(
      'Playback',
      [
        SwitchListTile(
          title: Text('Crossfade'),
          subtitle: Text('Smooth transition between songs'),
          value: _crossfadeEnabled,
          onChanged: (bool value) {
            setState(() {
              _crossfadeEnabled = value;
              _saveSetting('crossfadeEnabled', value);
            });
          },
        ),
        if (_crossfadeEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                    'Crossfade Duration: ${_crossfadeDuration.toStringAsFixed(1)}s'),
                Expanded(
                  child: Slider(
                    value: _crossfadeDuration,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: _crossfadeDuration.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _crossfadeDuration = value;
                        _saveSetting('crossfadeDuration', value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        SwitchListTile(
          title: Text('Gapless Playback'),
          subtitle: Text('Remove gaps between songs'),
          value: _gaplessPlayback,
          onChanged: (bool value) {
            setState(() {
              _gaplessPlayback = value;
              _saveSetting('gaplessPlayback', value);
            });
          },
        ),
        SwitchListTile(
          title: Text('Auto-play'),
          subtitle: Text('Start playing automatically'),
          value: _autoPlay,
          onChanged: (bool value) {
            setState(() {
              _autoPlay = value;
              _saveSetting('autoPlay', value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return _buildSection(
      'Audio',
      [
        ListTile(
          title: Text('Audio Quality'),
          subtitle: Text('Higher quality uses more data'),
          trailing: DropdownButton<String>(
            value: _audioQuality,
            items: ['Low', 'Medium', 'High'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _audioQuality = newValue;
                  _saveSetting('audioQuality', newValue);
                });
              }
            },
          ),
        ),
        Consumer<MediaPlayerViewModel>(
          builder: (context, mediaPlayer, _) => ListTile(
            title: Text('Equalizer'),
            subtitle: Text('Customize audio frequencies'),
            trailing: Icon(Icons.equalizer),
            onTap: () {
              // Show equalizer dialog
              showDialog(
                context: context,
                builder: (context) => _buildEqualizerDialog(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      'Notifications',
      [
        SwitchListTile(
          title: Text('Show Notifications'),
          subtitle: Text('Display media controls in notification'),
          value: _showNotification,
          onChanged: (bool value) {
            setState(() {
              _showNotification = value;
              _saveSetting('showNotification', value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildStorageSection() {
    return _buildSection(
      'Storage',
      [
        SwitchListTile(
          title: Text('Save Last Position'),
          subtitle: Text('Remember where you left off'),
          value: _saveLastPosition,
          onChanged: (bool value) {
            setState(() {
              _saveLastPosition = value;
              _saveSetting('saveLastPosition', value);
            });
          },
        ),
        ListTile(
          title: Text('Clear Cache'),
          subtitle: Text('Free up storage space'),
          trailing: Icon(Icons.cleaning_services),
          onTap: () async {
            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Clear Cache'),
                content: Text('Are you sure you want to clear the cache?'),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: Text('Clear'),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              // Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache cleared')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      [
        ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          title: Text('Licenses'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () => showLicensePage(context: context),
        ),
        ListTile(
          title: Text('Privacy Policy'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to privacy policy
          },
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildEqualizerDialog() {
    final List<double> frequencies = [
      60,
      170,
      310,
      600,
      1000,
      3000,
      6000,
      12000,
      14000,
      16000
    ];
    final List<double> gains = List.filled(10, 0.0);

    return AlertDialog(
      title: Text('Equalizer'),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  frequencies.length,
                  (index) => _buildEqualizerBand(
                    frequency: frequencies[index],
                    gain: gains[index],
                    onChanged: (value) {
                      // Implement equalizer changes
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text('Reset'),
                  onPressed: () {
                    // Reset equalizer
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualizerBand({
    required double frequency,
    required double gain,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: -1,
            child: Slider(
              value: gain,
              min: -12.0,
              max: 12.0,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          frequency < 1000
              ? '${frequency.toInt()}Hz'
              : '${(frequency / 1000).toStringAsFixed(1)}kHz',
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
