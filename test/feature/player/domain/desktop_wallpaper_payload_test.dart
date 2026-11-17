import 'dart:convert';
import 'dart:typed_data';

import 'package:bilimusic/feature/player/domain/desktop_wallpaper_payload.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:flutter_test/flutter_test.dart';

NowPlaying _nowPlaying({
  String title = '夜航星',
  String artist = '歌手',
  String? lyrics,
  String? sourceLabel,
}) {
  return NowPlaying(
    stableId: 's1',
    title: title,
    artist: artist,
    lyrics: lyrics,
    sourceLabel: sourceLabel,
  );
}

void main() {
  group('DesktopWallpaperPayload playbackState', () {
    test('maps playing item to 1', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(isPlaying: true, hasItem: true),
      );
      expect(payload.playbackState, DesktopWallpaperPayload.playbackPlaying);
      expect(payload.playbackState, 1);
    });

    test('maps paused item to 2', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(isPlaying: false, hasItem: true),
      );
      expect(payload.playbackState, DesktopWallpaperPayload.playbackPaused);
      expect(payload.playbackState, 2);
    });

    test('maps missing item to 3', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: null,
        playback: NowPlayingPlayback(isPlaying: false, hasItem: false),
      );
      expect(payload.playbackState, DesktopWallpaperPayload.playbackStopped);
      expect(payload.playbackState, 3);
    });
  });

  group('DesktopWallpaperPayload progressJson', () {
    test('uses seconds and state number', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(
          position: const Duration(milliseconds: 90500),
          duration: const Duration(milliseconds: 200000),
          isPlaying: true,
        ),
      );
      final Map<String, Object?> json = payload.progressJson();
      expect(json['position'], 90.5);
      expect(json['duration'], 200.0);
      expect(json['state'], 1);
    });

    test('falls back to zero duration when unknown', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(
          position: const Duration(seconds: 3),
          isPlaying: true,
        ),
      );
      expect(payload.progressJson()['duration'], 0.0);
    });

    test('json encodes to flat state body accepted by the shim', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(
          position: const Duration(seconds: 42),
          duration: const Duration(seconds: 100),
          isPlaying: true,
        ),
      );
      final Map<String, Object?> body = <String, Object?>{}
        ..addAll(payload.metadataJson())
        ..addAll(payload.progressJson());
      final Object decoded = jsonDecode(jsonEncode(body));
      expect(decoded, isA<Map<String, dynamic>>());
      expect((decoded as Map<String, dynamic>)['contentType'], 'music');
      expect(decoded['position'], 42.0);
    });
  });

  group('DesktopWallpaperPayload metadataJson', () {
    test('carries wallpaper Properties fields', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(sourceLabel: '每日推荐'),
        playback: NowPlayingPlayback(isPlaying: true),
      );
      expect(payload.metadataJson(), <String, Object?>{
        'title': '夜航星',
        'artist': '歌手',
        'albumTitle': '',
        'subTitle': '每日推荐',
        'genres': '',
        'contentType': 'music',
      });
    });

    test('metadataKey ignores lyrics and position', () {
      final DesktopWallpaperPayload first = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(),
        playback: NowPlayingPlayback(
          position: const Duration(seconds: 1),
          isPlaying: true,
        ),
      );
      final DesktopWallpaperPayload second = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(lyrics: '[00:01.00]line'),
        playback: NowPlayingPlayback(
          position: const Duration(seconds: 99),
          isPlaying: false,
        ),
      );
      expect(second.metadataKey, first.metadataKey);
      final DesktopWallpaperPayload third = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(title: '另一首'),
        playback: NowPlayingPlayback(isPlaying: true),
      );
      expect(third.metadataKey, isNot(first.metadataKey));
    });

    test('exposes lyrics for changed-lyrics push gating', () {
      final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
        nowPlaying: _nowPlaying(lyrics: '[00:01.00]line'),
        playback: NowPlayingPlayback(isPlaying: true),
      );
      expect(payload.lyrics, '[00:01.00]line');
      expect(
        DesktopWallpaperPayload(
          nowPlaying: null,
          playback: NowPlayingPlayback(),
        ).lyrics,
        '',
      );
    });
  });

  group('DesktopWallpaperPayload buildCoverDataUrl', () {
    test('prefixes png magic with image/png', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        1,
        2,
        3,
        4,
      ]);
      expect(
        DesktopWallpaperPayload.buildCoverDataUrl(bytes),
        'data:image/png;base64,${base64Encode(bytes)}',
      );
    });

    test('prefixes jpeg magic with image/jpeg', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0,
        16,
        74,
        70,
        73,
        70,
      ]);
      expect(
        DesktopWallpaperPayload.buildCoverDataUrl(bytes),
        'data:image/jpeg;base64,${base64Encode(bytes)}',
      );
    });

    test('prefixes webp magic with image/webp', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0x52,
        0x49,
        0x46,
        0x46,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);
      expect(
        DesktopWallpaperPayload.buildCoverDataUrl(bytes),
        'data:image/webp;base64,${base64Encode(bytes)}',
      );
    });

    test('falls back to image/jpeg for unknown bytes', () {
      final Uint8List bytes = Uint8List.fromList(<int>[0, 1, 2, 3]);
      expect(
        DesktopWallpaperPayload.buildCoverDataUrl(bytes),
        'data:image/jpeg;base64,${base64Encode(bytes)}',
      );
    });
  });
}
