import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bilimusic/common/util/platform_util.dart';
import 'package:bilimusic/core/cache/cache_util.dart';
import 'package:bilimusic/feature/player/domain/desktop_wallpaper_payload.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/logic/display/now_playing_provider.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:bilimusic/feature/player/logic/wallpaper/wallpaper_bridge.dart';
import 'package:bilimusic/feature/setting/logic/desktop_wallpaper_setting_logic.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_wallpaper_controller.g.dart';

@Riverpod(keepAlive: true)
class DesktopWallpaperController extends _$DesktopWallpaperController {
  static const Duration _pushDebounce = Duration(milliseconds: 180);
  static const Duration _progressInterval = Duration(milliseconds: 1000);

  Timer? _pushTimer;
  final Stopwatch _progressClock = Stopwatch();
  bool _pushing = false;
  bool _pushQueued = false;
  String? _lastMetadataKey;
  String? _lastThumbnail;
  String? _lastLyrics;
  int _lastState = -1;
  double _lastPositionSeconds = -1;
  String? _coverSourceUrl;
  Uint8List? _coverBytes;
  String? _coverDataUrl;
  bool _coverPending = false;

  @override
  bool build() {
    ref.onDispose(() {
      _pushTimer?.cancel();
      _progressClock.stop();
      DesktopWallpaperBridge.detach();
    });
    if (!PlatformUtil.isWindows) {
      return false;
    }
    _progressClock.start();
    DesktopWallpaperBridge.attach(
      onControl: _handleControl,
      onWindowClosed: _handleWindowClosed,
      onReady: _handleReady,
    );
    ref.listen<DesktopWallpaperSettings>(desktopWallpaperSettingLogicProvider, (
      DesktopWallpaperSettings? previous,
      DesktopWallpaperSettings next,
    ) {
      unawaited(Future<void>.microtask(() => _applySettings(next)));
    }, fireImmediately: true);
    ref.listen<NowPlaying?>(nowPlayingProvider, (NowPlaying? previous, _) {
      _schedulePush();
    });
    ref.listen<NowPlayingPlayback>(nowPlayingPlaybackProvider, (
      NowPlayingPlayback? previous,
      _,
    ) {
      _schedulePush();
    });
    return false;
  }

  Future<void> _applySettings(DesktopWallpaperSettings settings) async {
    if (!settings.enabled) {
      _pushTimer?.cancel();
      _pushTimer = null;
      _resetPushState();
      if (state) {
        state = false;
      }
      await DesktopWallpaperBridge.hide();
      return;
    }
    final bool shown = await DesktopWallpaperBridge.show(
      monitorIndex: settings.monitorIndex,
    );
    if (!ref.mounted) {
      return;
    }
    _resetPushState();
    state = shown;
    if (shown) {
      _schedulePush();
    }
  }

  void _schedulePush() {
    if (!state) {
      return;
    }
    _pushTimer ??= Timer(_pushDebounce, () {
      _pushTimer = null;
      unawaited(_push());
    });
  }

  Future<void> _push() async {
    if (!state) {
      return;
    }
    if (_pushing) {
      _pushQueued = true;
      return;
    }
    _pushing = true;
    try {
      await _pushBody();
    } finally {
      _pushing = false;
      if (_pushQueued) {
        _pushQueued = false;
        _schedulePush();
      }
    }
  }

  Future<void> _pushBody() async {
    final NowPlaying? nowPlaying = ref.read(nowPlayingProvider);
    final NowPlayingPlayback playback = ref.read(nowPlayingPlaybackProvider);
    final DesktopWallpaperPayload payload = DesktopWallpaperPayload(
      nowPlaying: nowPlaying,
      playback: playback,
    );
    final Map<String, Object?> body = <String, Object?>{};
    if (nowPlaying == null) {
      if (payload.playbackState != _lastState) {
        _lastState = payload.playbackState;
        body['state'] = payload.playbackState;
        await _send(body);
      }
      return;
    }
    final String? thumbnail = await _resolveThumbnail(nowPlaying.coverUrl);
    if (!ref.mounted || !state) {
      return;
    }
    if (payload.metadataKey != _lastMetadataKey) {
      _lastMetadataKey = payload.metadataKey;
      body.addAll(payload.metadataJson());
    }
    if (thumbnail != null && thumbnail != _lastThumbnail) {
      _lastThumbnail = thumbnail;
      body['thumbnail'] = thumbnail;
    }
    final String lyrics = payload.lyrics;
    if (lyrics != _lastLyrics) {
      _lastLyrics = lyrics;
      // 即使为空也发送，让壁纸端清掉上一首的歌词/解除外部锁定。
      body['lyrics'] = lyrics;
    }
    final int stateValue = payload.playbackState;
    final double positionSeconds = payload.positionSeconds;
    final bool stateChanged = stateValue != _lastState;
    final bool progressDue =
        _progressClock.elapsed >= _progressInterval &&
        positionSeconds != _lastPositionSeconds;
    if (stateChanged || progressDue) {
      _lastState = stateValue;
      _lastPositionSeconds = positionSeconds;
      _progressClock.reset();
      body.addAll(payload.progressJson());
    }
    await _send(body);
  }

  Future<void> _send(Map<String, Object?> body) async {
    if (body.isEmpty) {
      return;
    }
    await DesktopWallpaperBridge.pushState(payload: jsonEncode(body));
  }

  Future<String?> _resolveThumbnail(String? coverUrl) async {
    if (coverUrl == null || coverUrl.trim().isEmpty) {
      _coverSourceUrl = null;
      return '';
    }
    if (coverUrl != _coverSourceUrl) {
      _coverSourceUrl = coverUrl;
      _coverBytes = null;
      _coverDataUrl = null;
      _coverPending = true;
    }
    if (_coverPending && _coverBytes == null) {
      final Uint8List? bytes = await _readCoverBytes(coverUrl);
      if (bytes != null) {
        _coverBytes = bytes;
        _coverPending = false;
      }
    }
    final Uint8List? bytes = _coverBytes;
    if (bytes != null && _coverDataUrl == null) {
      if (_coverPending) {
        return DesktopWallpaperPayload.buildCoverDataUrl(bytes);
      }
      _coverDataUrl = DesktopWallpaperPayload.buildCoverDataUrl(bytes);
    }
    return _coverDataUrl;
  }

  Future<Uint8List?> _readCoverBytes(String url) async {
    final FileInfo? cached = await CacheUtil.getImageCache(url);
    final File? file = cached?.file;
    if (file == null) {
      return null;
    }
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  void _resetPushState() {
    _lastMetadataKey = null;
    _lastThumbnail = null;
    _lastLyrics = null;
    _lastState = -1;
    _lastPositionSeconds = -1;
    _progressClock.reset();
  }

  void _handleReady() {
    _resetPushState();
    if (state) {
      _schedulePush();
    }
  }

  void _handleControl(Map<Object?, Object?> arguments) {
    final PlayerController controller = ref.read(
      playerControllerProvider.notifier,
    );
    final Object? type = arguments['type'];
    if (type == 'toggle') {
      unawaited(controller.togglePlayback());
    } else if (type == 'play') {
      unawaited(controller.play());
    } else if (type == 'pause') {
      unawaited(controller.pause());
    } else if (type == 'previous') {
      unawaited(controller.skipToPrevious());
    } else if (type == 'next') {
      unawaited(controller.skipToNext());
    } else if (type == 'seek') {
      final Object? positionMs = arguments['positionMs'];
      if (positionMs is num && positionMs >= 0) {
        unawaited(controller.seek(Duration(milliseconds: positionMs.round())));
      }
    } else {
      return;
    }
    _schedulePush();
  }

  void _handleWindowClosed() {
    _pushTimer?.cancel();
    _pushTimer = null;
    _resetPushState();
    if (state) {
      state = false;
    }
    unawaited(
      ref.read(desktopWallpaperSettingLogicProvider.notifier).setEnabled(false),
    );
  }
}
