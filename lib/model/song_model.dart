import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as path;

class SongModel {
  // Core properties
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration? duration;
  final Uri? artworkUri;

  // Audio source for just_audio
  late final AudioSource audioSource;

  SongModel({
    required this.filePath,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.duration,
    this.artworkUri,
    String? id,
  }) : id = id ?? filePath {
    // Create the audio source with the MediaItem tag
    audioSource = AudioSource.uri(
      Uri.file(filePath),
      tag: metadata,
    );
  }

  // Factory constructor to create a SongModel from a file path
  factory SongModel.fromFilePath(String filePath) {
    final fileName = path.basename(filePath);
    final title = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    return SongModel(
      filePath: filePath,
      title: title,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: const Duration(seconds: 0), // Default duration that will be updated when playing
    );
  }

  // Factory constructor to create a SongModel from a MediaItem
  factory SongModel.fromMediaItem(MediaItem mediaItem) {
    return SongModel(
      id: mediaItem.id,
      filePath: mediaItem.id, // Assuming id is the file path
      title: mediaItem.title,
      artist: mediaItem.artist ?? 'Unknown Artist',
      album: mediaItem.album ?? 'Unknown Album',
      duration: mediaItem.duration,
      artworkUri: mediaItem.artUri,
    );
  }

  // Convert to MediaItem for just_audio_background
  MediaItem get metadata => MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        artUri: artworkUri,
      );

  // Check if the file exists
  bool get exists => File(filePath).existsSync();

  // Get file size
  Future<int> get fileSize async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // Get file extension
  String get fileExtension {
    return path.extension(filePath).replaceFirst('.', '').toLowerCase();
  }

  // Format duration as a string (e.g., "3:45")
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes =
        duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Create a copy of this SongModel with some properties changed
  SongModel copyWith({
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    Uri? artworkUri,
  }) {
    return SongModel(
      filePath: filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUri: artworkUri ?? this.artworkUri,
      id: id,
    );
  }

  @override
  String toString() => 'SongModel(title: $title, artist: $artist)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
