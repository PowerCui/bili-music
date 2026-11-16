import 'package:flutter/services.dart';

typedef WallpaperControlHandler = void Function(Map<Object?, Object?> arguments);
typedef WallpaperStateHandler =
    void Function(String? payload, Uint8List? cover);

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
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> entry) {
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
          })
          .toList();
    } on PlatformException {
      return const <WallpaperMonitor>[];
    } on MissingPluginException {
      return const <WallpaperMonitor>[];
    }
  }

  static void attach({
    required WallpaperControlHandler onControl,
    required VoidCallback onWindowClosed,
  }) {
    channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'control':
          final Object? arguments = call.arguments;
          if (arguments is Map<Object?, Object?>) {
            onControl(arguments);
          }
          return;
        case 'windowClosed':
          onWindowClosed();
          return;
        default:
          return;
      }
    });
  }

  static void detach() {
    channel.setMethodCallHandler(null);
  }
}

class WallpaperViewBridge {
  static const MethodChannel channel = MethodChannel(
    'bilimusic/desktop_wallpaper_view',
  );

  static Future<void> notifyReady() async {
    try {
      await channel.invokeMethod<void>('ready');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> sendControl(Map<String, Object?> arguments) async {
    try {
      await channel.invokeMethod<void>('control', arguments);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  static void attach({required WallpaperStateHandler onState}) {
    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'state') {
        return;
      }
      final Object? arguments = call.arguments;
      if (arguments is! Map<Object?, Object?>) {
        return;
      }
      final Object? payload = arguments['payload'];
      final Object? cover = arguments['cover'];
      onState(
        payload is String ? payload : null,
        cover is Uint8List ? cover : null,
      );
    });
  }

  static void detach() {
    channel.setMethodCallHandler(null);
  }
}
