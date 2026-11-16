import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bilimusic/common/logger.dart';
import 'package:bilimusic/core/bridge/bridge_protocol.dart';
import 'package:bilimusic/core/bridge/bridge_snapshot.dart';
import 'package:bilimusic/feature/metadata/domain/metadata.dart';
import 'package:bilimusic/feature/metadata/logic/metadata_controller.dart';
import 'package:bilimusic/feature/player/domain/bili_subtitle.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';
import 'package:bilimusic/feature/player/domain/player_state.dart';
import 'package:bilimusic/feature/player/domain/player_subtitle_state.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_provider.dart';
import 'package:bilimusic/feature/player/logic/lyrics/player_subtitle_controller.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 本地桥接服务：把「当前正在播的曲目」连同封面和歌词暴露给本机其它程序。
///
/// 只监听 127.0.0.1，数据接口要带令牌。
class LocalBridgeServer {
  LocalBridgeServer._();

  static final LocalBridgeServer instance = LocalBridgeServer._();

  final AppLogger _logger = AppLogger('LocalBridge');
  final HttpClient _httpClient = HttpClient();
  final Map<String, _CoverEntry> _coverCache = <String, _CoverEntry>{};

  HttpServer? _server;
  ProviderContainer? _container;

  /// 实际监听的端口。被占用时会顺延，壁纸按同样的范围去找。
  int get port => _server?.port ?? BridgeProtocol.defaultPort;

  /// 服务是否在跑。
  bool get isRunning => _server != null;

  /// 启动服务。已经在跑时直接返回 true。
  Future<bool> start(ProviderContainer container) async {
    if (_server != null) {
      return true;
    }
    _container = container;
    final List<int> candidates = BridgeProtocol.candidatePorts();
    for (final int candidate in candidates) {
      try {
        final HttpServer server = await HttpServer.bind(
          InternetAddress(BridgeProtocol.host, type: InternetAddressType.IPv4),
          candidate,
        );
        _server = server;
        _logger.i('本地桥接已启动 http://${BridgeProtocol.host}:$candidate');
        server.listen(
          _handleRequest,
          onError: (Object error, StackTrace stackTrace) {
            _logger.e('本地桥接处理请求出错', error, stackTrace);
          },
          cancelOnError: false,
        );
        return true;
      } on SocketException {
        continue;
      } on Object catch (error) {
        _logger.e('本地桥接启动失败', error);
        break;
      }
    }
    _logger.w('本地桥接启动失败：端口都被占用了');
    return false;
  }

  /// 停掉服务。
  Future<void> stop() async {
    final HttpServer? server = _server;
    _server = null;
    _container = null;
    if (server == null) {
      return;
    }
    try {
      await server.close(force: true);
    } on Object {
      // Ignore shutdown failures.
    }
    try {
      _httpClient.close(force: true);
    } on Object {
      // Ignore shutdown failures.
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final HttpResponse response = request.response;
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', '*');
    response.headers.set('Cache-Control', 'no-store');

    try {
      if (request.method == 'OPTIONS') {
        response.statusCode = HttpStatus.noContent;
        await response.close();
        return;
      }

      final Uri uri = request.uri;
      if (uri.path == BridgeProtocol.healthPath) {
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode(<String, dynamic>{
            'ok': true,
            'v': BridgeProtocol.version,
            'app': BridgeProtocol.appName,
          }),
        );
        await response.close();
        return;
      }

      if (!BridgeProtocol.isAuthorized(uri.queryParameters)) {
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }

      if (uri.path == BridgeProtocol.nowPath) {
        await _serveNow(response);
        return;
      }
      if (uri.path == BridgeProtocol.lyricsPath) {
        await _serveLyrics(response);
        return;
      }
      if (uri.path == BridgeProtocol.coverPath) {
        await _serveCover(response);
        return;
      }
      response.statusCode = HttpStatus.notFound;
      await response.close();
    } on Object catch (error, stackTrace) {
      _logger.e('本地桥接请求处理失败', error, stackTrace);
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } on Object {
        // The response is already gone.
      }
    }
  }

  Future<void> _serveNow(HttpResponse response) async {
    final BridgeSnapshot snapshot = _buildSnapshot();
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(snapshot.toJson(port)));
    await response.close();
  }

  Future<void> _serveLyrics(HttpResponse response) async {
    final BridgeSnapshot snapshot = _buildSnapshot();
    response.headers.contentType = ContentType(
      'text',
      'plain',
      charset: 'utf-8',
    );
    response.write(snapshot.lyrics);
    await response.close();
  }

  Future<void> _serveCover(HttpResponse response) async {
    final BridgeSnapshot snapshot = _buildSnapshot();
    final String? source = snapshot.coverUrl;
    if (source == null || source.trim().isEmpty) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    final _CoverEntry? entry = await _loadCover(source);
    if (entry == null) {
      response.statusCode = HttpStatus.badGateway;
      await response.close();
      return;
    }
    response.headers.contentType = ContentType.parse(entry.mimeType);
    response.add(entry.bytes);
    await response.close();
  }

  Future<_CoverEntry?> _loadCover(String url) async {
    final _CoverEntry? cached = _coverCache[url];
    if (cached != null) {
      return cached;
    }
    try {
      final HttpClientRequest request = await _httpClient.getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse source = await request.close();
      if (source.statusCode != HttpStatus.ok) {
        await source.drain<void>();
        return null;
      }
      final Uint8List bytes = await source.fold<Uint8List>(
        Uint8List(0),
        (Uint8List buffer, List<int> chunk) => buffer..addAll(chunk),
      );
      final String upstreamMime = source.headers.contentType?.mimeType ?? '';
      final _CoverEntry entry = _CoverEntry(
        bytes,
        upstreamMime.contains('/') ? upstreamMime : 'image/jpeg',
      );
      if (_coverCache.length >= 8) {
        _coverCache.remove(_coverCache.keys.first);
      }
      _coverCache[url] = entry;
      return entry;
    } on Object catch (error) {
      _logger.w('封面抓取失败：$error');
      return null;
    }
  }

  /// 采样一次当前播放状态。
  BridgeSnapshot _buildSnapshot() {
    final ProviderContainer? container = _container;
    if (container == null) {
      return const BridgeSnapshot.empty();
    }

    try {
      final PlayerState player = container.read(playerControllerProvider);
      final PlayableItem? item = player.currentItem;
      if (item == null) {
        return const BridgeSnapshot.empty();
      }

      final String title = _readTitle(container, item);
      if (title.trim().isEmpty) {
        return const BridgeSnapshot.empty();
      }

      final String artist = _readArtist(container, item);
      final String? coverUrl = _readCoverUrl(container, item);
      final _LyricsPayload lyrics = _readLyrics(container, item);
      final int lyricsOffsetMs = _readLyricsOffsetMs(container, item);
      final Duration? duration = player.duration;

      return BridgeSnapshot(
        active: true,
        playing: player.isPlaying,
        title: title,
        artist: artist,
        album: player.queueSourceLabel?.trim() ?? '',
        coverUrl: coverUrl,
        position: player.position.inMilliseconds / 1000,
        duration: duration == null ? 0 : duration.inMilliseconds / 1000,
        lyrics: lyrics.text,
        lyricsSource: lyrics.source,
        lyricsOffsetMs: lyricsOffsetMs,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    } on Object catch (error, stackTrace) {
      _logger.e('采样播放状态失败', error, stackTrace);
      return const BridgeSnapshot.empty();
    }
  }

  String _readTitle(ProviderContainer container, PlayableItem item) {
    try {
      final display = container.read(playerDisplayProvider);
      if (display.stableId == item.stableId) {
        final String? title = display.title;
        if (title != null && title.trim().isNotEmpty) {
          return title.trim();
        }
      }
    } on Object {
      // Fall through to the raw item title.
    }
    return item.title;
  }

  String _readArtist(ProviderContainer container, PlayableItem item) {
    try {
      final display = container.read(playerDisplayProvider);
      if (display.stableId == item.stableId) {
        final String? artist = display.artist;
        if (artist != null && artist.trim().isNotEmpty) {
          return artist.trim();
        }
      }
    } on Object {
      // Fall through to the raw item author.
    }
    return item.author;
  }

  String? _readCoverUrl(ProviderContainer container, PlayableItem item) {
    try {
      final display = container.read(playerDisplayProvider);
      if (display.stableId == item.stableId) {
        final String? coverUrl = display.coverUrl;
        if (coverUrl != null && coverUrl.trim().isNotEmpty) {
          return coverUrl.trim();
        }
      }
    } on Object {
      // Fall through to the raw item cover.
    }
    final String cover = item.coverUrl.trim();
    return cover.isEmpty ? null : cover;
  }

  _LyricsPayload _readLyrics(ProviderContainer container, PlayableItem item) {
    final PlayerSubtitleState? subtitles = _readSubtitles(container, item);
    if (subtitles != null && subtitles.usesSubtitles) {
      return _LyricsPayload(
        _subtitleToLrc(subtitles.lines),
        'subtitle',
      );
    }

    final Metadata? metadata = _readMetadata(container, item);
    if (metadata != null) {
      // 只取 LRC / 纯文本；karaoke 那份是 KRC 格式，壁纸解析不了。
      final String? lrc = metadata.lyrics?.trim();
      final String? main = metadata.metaLyrics?.lyric?.trim();
      final String text = (lrc != null && lrc.isNotEmpty)
          ? lrc
          : (main ?? '');
      if (text.isNotEmpty) {
        return _LyricsPayload(text, 'meting');
      }
    }
    return const _LyricsPayload('', 'none');
  }

  int _readLyricsOffsetMs(ProviderContainer container, PlayableItem item) {
    final PlayerSubtitleState? subtitles = _readSubtitles(container, item);
    if (subtitles != null && subtitles.usesSubtitles) {
      return _toWallpaperOffset(subtitles.offsetMs);
    }
    final Metadata? metadata = _readMetadata(container, item);
    if (metadata != null) {
      return _toWallpaperOffset(
        metadata.lyricBaseOffsetMs + metadata.lyricOffsetMs,
      );
    }
    return 0;
  }

  /// bilimusic 里正值 = 歌词提前出现，壁纸里正值 = 歌词延后出现，这里取反。
  int _toWallpaperOffset(int biliMusicOffsetMs) {
    return -biliMusicOffsetMs;
  }

  PlayerSubtitleState? _readSubtitles(
    ProviderContainer container,
    PlayableItem item,
  ) {
    try {
      final PlayerSubtitleState state = container.read(
        playerSubtitleControllerProvider,
      );
      if (state.stableId != item.stableId) {
        return null;
      }
      return state;
    } on Object {
      return null;
    }
  }

  Metadata? _readMetadata(ProviderContainer container, PlayableItem item) {
    try {
      final metadataState = container.read(metadataControllerProvider);
      final Metadata? metadata = metadataState.metadata;
      if (metadata == null || metadata.stableId != item.stableId) {
        return null;
      }
      return metadata;
    } on Object {
      return null;
    }
  }

  /// 把 B 站字幕行转成 LRC。
  String _subtitleToLrc(List<BiliSubtitleLine> lines) {
    final StringBuffer buffer = StringBuffer();
    for (final BiliSubtitleLine line in lines) {
      final String text = line.text.trim();
      if (text.isEmpty) {
        continue;
      }
      buffer
        ..write(_formatLrcTime(line.startMs))
        ..write(text)
        ..write('\n');
    }
    return buffer.toString();
  }

  String _formatLrcTime(int milliseconds) {
    final int total = milliseconds < 0 ? 0 : milliseconds;
    final int minutes = total ~/ 60000;
    final int seconds = (total % 60000) ~/ 1000;
    final int hundredths = (total % 1000) ~/ 10;
    final String minuteText = minutes.toString().padLeft(2, '0');
    final String secondText = seconds.toString().padLeft(2, '0');
    final String fractionText = hundredths.toString().padLeft(2, '0');
    return '[$minuteText:$secondText.$fractionText]';
  }
}

class _CoverEntry {
  const _CoverEntry(this.bytes, this.mimeType);

  final Uint8List bytes;
  final String mimeType;
}

class _LyricsPayload {
  const _LyricsPayload(this.text, this.source);

  final String text;
  final String source;
}
