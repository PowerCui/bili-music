import 'dart:async';
import 'dart:typed_data';

import 'package:bilimusic/feature/player/domain/desktop_wallpaper_payload.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/logic/wallpaper/wallpaper_bridge.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_player_view.dart';
import 'package:flutter/material.dart';

class WallpaperApp extends StatefulWidget {
  const WallpaperApp({super.key});

  @override
  State<WallpaperApp> createState() => _WallpaperAppState();
}

class _WallpaperAppState extends State<WallpaperApp> {
  DesktopWallpaperPayload? _payload;
  Uint8List? _coverBytes;

  @override
  void initState() {
    super.initState();
    WallpaperViewBridge.attach(onState: _handleState);
    unawaited(WallpaperViewBridge.notifyReady());
  }

  @override
  void dispose() {
    WallpaperViewBridge.detach();
    super.dispose();
  }

  void _handleState(String? rawPayload, Uint8List? cover) {
    final DesktopWallpaperPayload? payload = DesktopWallpaperPayload.decode(
      rawPayload,
    );
    if (payload == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _payload = payload;
      if (cover != null) {
        _coverBytes = cover;
      }
    });
  }

  void _sendControl(String type, {double? positionMs}) {
    unawaited(
      WallpaperViewBridge.sendControl(<String, Object?>{
        'type': type,
        if (positionMs != null) 'positionMs': positionMs,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DesktopWallpaperPayload? payload = _payload;
    final Color accentColor = payload == null
        ? const Color(0xFF3B6FF5)
        : Color(payload.accentColorValue);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bilimusic wallpaper',
      home: CdPlayerView(
        nowPlaying: payload?.nowPlaying.copyWith(coverUrl: null),
        playback: payload?.playback ?? const NowPlayingPlayback(),
        accentColor: accentColor,
        coverBytes: _coverBytes,
        padding: const EdgeInsets.fromLTRB(64, 56, 64, 48),
        onTogglePlayback: () => _sendControl('toggle'),
        onPrevious: () => _sendControl('previous'),
        onNext: () => _sendControl('next'),
        onSeek: (Duration position) => _sendControl(
          'seek',
          positionMs: position.inMilliseconds.toDouble(),
        ),
      ),
    );
  }
}
