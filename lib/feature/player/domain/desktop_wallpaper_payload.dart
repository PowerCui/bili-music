import 'dart:convert';

import 'package:bilimusic/feature/player/domain/now_playing.dart';

class DesktopWallpaperPayload {
  const DesktopWallpaperPayload({
    required this.nowPlaying,
    required this.playback,
    required this.accentColorValue,
  });

  final NowPlaying nowPlaying;
  final NowPlayingPlayback playback;
  final int accentColorValue;

  static const int schemaVersion = 1;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'v': schemaVersion,
      'stableId': nowPlaying.stableId,
      'title': nowPlaying.title,
      'artist': nowPlaying.artist,
      'coverUrl': nowPlaying.coverUrl,
      'lyrics': nowPlaying.lyrics,
      'translationLyrics': nowPlaying.translationLyrics,
      'lyricOffsetMs': nowPlaying.lyricOffsetMs,
      'durationMs': nowPlaying.duration?.inMilliseconds,
      'accentColor': accentColorValue,
      'playback': <String, Object?>{
        'positionMs': playback.position.inMilliseconds,
        'durationMs': playback.duration?.inMilliseconds,
        'isPlaying': playback.isPlaying,
        'isReady': playback.isReady,
        'isBuffering': playback.isBuffering,
        'isLoading': playback.isLoading,
        'speed': playback.speed,
        'hasPrevious': playback.hasPrevious,
        'hasNext': playback.hasNext,
        'hasItem': playback.hasItem,
      },
    };
  }

  String encode() => jsonEncode(toJson());

  static DesktopWallpaperPayload? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  static DesktopWallpaperPayload fromJson(Map<String, Object?> json) {
    final Object? playbackRaw = json['playback'];
    final Map<String, Object?> playbackJson = playbackRaw is Map
        ? Map<String, Object?>.from(playbackRaw)
        : const <String, Object?>{};
    final NowPlaying nowPlaying = NowPlaying(
      stableId: _readString(json['stableId']) ?? '',
      title: _readString(json['title']) ?? '',
      artist: _readString(json['artist']) ?? '',
      coverUrl: _readString(json['coverUrl']),
      lyrics: _readString(json['lyrics']),
      translationLyrics: _readString(json['translationLyrics']),
      lyricOffsetMs: _readInt(json['lyricOffsetMs']) ?? 0,
      duration: _readDuration(json['durationMs']),
    );
    final NowPlayingPlayback playback = NowPlayingPlayback(
      position: _readDuration(playbackJson['positionMs']) ?? Duration.zero,
      duration: _readDuration(playbackJson['durationMs']),
      isPlaying: _readBool(playbackJson['isPlaying']),
      isReady: _readBool(playbackJson['isReady']),
      isBuffering: _readBool(playbackJson['isBuffering']),
      isLoading: _readBool(playbackJson['isLoading']),
      speed: _readDouble(playbackJson['speed']) ?? 1,
      hasPrevious: _readBool(playbackJson['hasPrevious']),
      hasNext: _readBool(playbackJson['hasNext']),
      hasItem: _readBool(playbackJson['hasItem'], fallback: true),
    );
    return DesktopWallpaperPayload(
      nowPlaying: nowPlaying,
      playback: playback,
      accentColorValue: _readInt(json['accentColor']) ?? 0xFF3B6FF5,
    );
  }

  static String? _readString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  static Duration? _readDuration(Object? value) {
    final int? milliseconds = _readInt(value);
    if (milliseconds == null) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }
}
