import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bilimusic/common/util/platform_util.dart';
import 'package:bilimusic/core/cache/cache_util.dart';
import 'package:bilimusic/feature/player/domain/desktop_wallpaper_payload.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/logic/display/now_playing_provider.dart';
import 'package:bilimusic/feature/player/logic/display/player_cover_color_provider.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:bilimusic/feature/player/logic/wallpaper/wallpaper_bridge.dart';
import 'package:bilimusic/feature/setting/logic/desktop_wallpaper_setting_logic.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_wallpaper_controller.g.dart';

@Riverpod(keepAlive: true)
class DesktopWallpaperController extends _$DesktopWallpaperController {
  Timer? _pushTimer;
  String? _lastPayload;
  String? _coverSourceUrl;
  Uint8List? _coverBytes;
  bool _coverPending = false;
  bool _coverSent = false;

  @override
  bool build() {
    ref.onDispose(() {
      _pushTimer?.cancel();
      DesktopWallpaperBridge.detach();
    });
    if (!PlatformUtil.isWindows) {
      return false;
    }
    DesktopWallpaperBridge.attach(
      onControl: _handleControl,
      onWindowClosed: _handleWindowClosed,
    );
    ref.listen<DesktopWallpaperSettings>(
      desktopWallpaperSettingLogicProvider,
      (DesktopWallpaperSettings? previous, DesktopWallpaperSettings next) {
        unawaited(Future<void>.microtask(() => _applySettings(next)));
      },
      fireImmediately: true,
    );
    ref.listen<NowPlaying?>(nowPlayingProvider, (NowPlaying? previous, _) {
      _schedulePush();
    });
    ref.listen<NowPlayingPlayback>(
      nowPlayingPlaybackProvider,
      (NowPlayingPlayback? previous, _) {
        _schedulePush();
      },
    );
    ref.listen<Color?>(playerCoverColorControllerProvider, (Color? previous, _) {
      _schedulePush();
    });
    return false;
  }

  Future<void> _applySettings(DesktopWallpaperSettings settings) async {
    if (!settings.enabled) {
      _pushTimer?.cancel();
      _pushTimer = null;
      _lastPayload = null;
      _coverSent = false;
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
    _lastPayload = null;
    _coverSent = false;
    state = shown;
    if (shown) {
      _schedulePush();
    }
  }

  void _schedulePush() {
    if (!state) {
      return;
    }
    _pushTimer ??= Timer(const Duration(milliseconds: 180), () {
      _pushTimer = null;
      unawaited(_push());
    });
  }

  Future<void> _push() async {
    if (!state) {
      return;
    }
    final NowPlaying? nowPlaying = ref.read(nowPlayingProvider);
    if (nowPlaying == null) {
      return;
    }
    final NowPlayingPlayback playback = ref.read(nowPlayingPlaybackProvider);
    final Color accentColor =
        ref.read(playerCoverColorControllerProvider) ?? const Color(0xFF3B6FF5);
    final String? coverUrl = nowPlaying.coverUrl;
    if (coverUrl != _coverSourceUrl) {
      _coverSourceUrl = coverUrl;
      _coverBytes = null;
      _coverPending = true;
      _coverSent = false;
    }
    if (_coverPending && coverUrl != null) {
      final Uint8List? bytes = await _readCoverBytes(coverUrl);
      if (bytes != null) {
        _coverBytes = bytes;
        _coverPending = false;
      }
    }
    if (!ref.mounted || !state) {
      return;
    }
    final String payload = DesktopWallpaperPayload(
      nowPlaying: nowPlaying,
      playback: playback,
      accentColorValue: accentColor.toARGB32(),
    ).encode();
    final bool sendCover = !_coverSent && _coverBytes != null;
    if (!sendCover && payload == _lastPayload) {
      return;
    }
    _lastPayload = payload;
    if (sendCover) {
      _coverSent = true;
    }
    await DesktopWallpaperBridge.pushState(
      payload: payload,
      cover: sendCover ? _coverBytes : null,
    );
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
    _lastPayload = null;
    _coverSent = false;
    if (state) {
      state = false;
    }
    unawaited(
      ref.read(desktopWallpaperSettingLogicProvider.notifier).setEnabled(false),
    );
  }
}
