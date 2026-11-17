import 'dart:convert';
import 'dart:typed_data';

import 'package:bilimusic/feature/player/domain/now_playing.dart';

class DesktopWallpaperPayload {
  const DesktopWallpaperPayload({
    required this.nowPlaying,
    required this.playback,
  });

  final NowPlaying? nowPlaying;
  final NowPlayingPlayback playback;

  static const int playbackPlaying = 1;
  static const int playbackPaused = 2;
  static const int playbackStopped = 3;
  static const String contentTypeMusic = 'music';

  String get title => nowPlaying?.title ?? '';
  String get artist => nowPlaying?.artist ?? '';
  String get albumTitle => '';
  String get subTitle => nowPlaying?.sourceLabel ?? '';
  String get genres => '';
  String get contentType => contentTypeMusic;
  String get lyrics => nowPlaying?.lyrics ?? '';

  String get metadataKey => <String>[
    title,
    artist,
    albumTitle,
    subTitle,
    genres,
    contentType,
  ].join('\u0000');

  int get playbackState {
    if (!playback.hasItem) {
      return playbackStopped;
    }
    return playback.isPlaying ? playbackPlaying : playbackPaused;
  }

  double get positionSeconds => playback.position.inMilliseconds / 1000;

  double get durationSeconds => (playback.duration?.inMilliseconds ?? 0) / 1000;

  Map<String, Object?> metadataJson() {
    return <String, Object?>{
      'title': title,
      'artist': artist,
      'albumTitle': albumTitle,
      'subTitle': subTitle,
      'genres': genres,
      'contentType': contentType,
    };
  }

  Map<String, Object?> progressJson() {
    return <String, Object?>{
      'position': positionSeconds,
      'duration': durationSeconds,
      'state': playbackState,
    };
  }

  static String buildCoverDataUrl(Uint8List bytes) {
    return 'data:${_sniffImageMime(bytes)};base64,${base64Encode(bytes)}';
  }

  static String _sniffImageMime(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
