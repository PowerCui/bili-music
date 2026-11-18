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
  String get lyrics => _qrcToLrc(nowPlaying?.lyrics ?? '');

  static final RegExp _qrcLine = RegExp(r'^\[(\d+),(\d+)(?:,\d+)?\]\s*(.*)$');
  static final RegExp _qrcAny = RegExp(r'\[\d+,\d+(?:,\d+)?\]');
  static final RegExp _qrcWord = RegExp(
    r'(?:\(-?\d+,-?\d+(?:,-?\d+)?\)|<-?\d+,-?\d+(?:,-?\d+)?>)',
  );

  /// 壁纸的歌词引擎只认标准 LRC（[mm:ss.cc]）。App 内部为了逐字效果会把 LRC
  /// 转成 QRC（[起始ms,时长ms]词(ms,ms)...），这里把 QRC 还原成 LRC，
  /// 保证桌面壁纸能解析显示；已是 LRC/纯文本则原样返回。
  static String _qrcToLrc(String raw) {
    final String s = raw.trim();
    if (s.isEmpty) return '';
    if (!_qrcAny.hasMatch(s)) return s;
    final List<String> out = <String>[];
    for (final String line in s.split(RegExp(r'\r?\n'))) {
      final RegExpMatch? m = _qrcLine.firstMatch(line.trim());
      if (m == null) continue;
      final int startMs = int.parse(m.group(1)!);
      final String text = m.group(3)!.replaceAll(_qrcWord, '').trim();
      if (text.isEmpty) continue;
      final String mm = (startMs ~/ 60000).toString().padLeft(2, '0');
      final String ss = ((startMs % 60000) / 1000).toStringAsFixed(2).padLeft(5, '0');
      out.add('[$mm:$ss]$text');
    }
    return out.join('\n');
  }

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
