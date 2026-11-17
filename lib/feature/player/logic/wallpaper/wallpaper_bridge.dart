import 'dart:convert';

import 'package:flutter/services.dart';

typedef WallpaperControlHandler =
    void Function(Map<Object?, Object?> arguments);
typedef WallpaperReadyHandler = void Function();

class WallpaperMonitor {
  const WallpaperMonitor({
    required this.index,
    required this.width,
    required this.height,
    required this.isPrimary,
  });

  final int index;
  final int width;
  final int height;
  final bool isPrimary;

  String get label => isPrimary ? '显示器 ${index + 1}（主屏）' : '显示器 ${index + 1}';
}

class DesktopWallpaperBridge {
  static const MethodChannel channel = MethodChannel(
    'bilimusic/desktop_wallpaper',
  );

  static Future<bool> show({required int monitorIndex}) async {
    try {
      final bool? shown = await channel.invokeMethod<bool>(
        'show',
        <String, Object?>{'monitorIndex': monitorIndex},
      );
      return shown ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> hide() async {
    try {
      await channel.invokeMethod<void>('hide');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> pushState({
    required String payload,
    Uint8List? cover,
  }) async {
    try {
      await channel.invokeMethod<void>('pushState', <String, Object?>{
        'payload': payload,
        'cover': cover,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static Future<List<WallpaperMonitor>> listMonitors() async {
    try {
      final List<Object?>? raw = await channel.invokeMethod<List<Object?>>(
        'listMonitors',
      );
      if (raw == null) {
        return const <WallpaperMonitor>[];
      }
      return raw.whereType<Map<Object?, Object?>>().map((
        Map<Object?, Object?> entry,
      ) {
        final Object? index = entry['index'];
        final Object? width = entry['width'];
        final Object? height = entry['height'];
        final Object? primary = entry['primary'];
        return WallpaperMonitor(
          index: index is int ? index : 0,
          width: width is int ? width : 0,
          height: height is int ? height : 0,
          isPrimary: primary is bool && primary,
        );
      }).toList();
    } on PlatformException {
      return const <WallpaperMonitor>[];
    } on MissingPluginException {
      return const <WallpaperMonitor>[];
    }
  }

  static void attach({
    required WallpaperControlHandler onControl,
    required VoidCallback onWindowClosed,
    WallpaperReadyHandler? onReady,
  }) {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'control':
          final Object? arguments = call.arguments;
          if (arguments is Map<Object?, Object?>) {
            onControl(_decodeControlBody(arguments));
          }
          return;
        case 'ready':
          onReady?.call();
          return;
        case 'windowClosed':
          onWindowClosed();
          return;
        default:
          return;
      }
    });
  }

  static Map<Object?, Object?> _decodeControlBody(
    Map<Object?, Object?> arguments,
  ) {
    final Object? raw = arguments['payload'];
    if (raw is! String || raw.isEmpty) {
      return arguments;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<Object?, Object?>.from(decoded);
      }
    } on FormatException {
      return arguments;
    }
    return arguments;
  }

  static void detach() {
    channel.setMethodCallHandler(null);
  }
}
