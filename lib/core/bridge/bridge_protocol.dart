/// 本地桥接协议：bilimusic ↔ Wallpaper Engine 壁纸。
///
/// 壁纸跑在 Wallpaper Engine 的内嵌网页里，只能读 Windows 媒体会话（SMTC）。
/// SMTC 只有标题 / 歌手 / 专辑 / 封面 / 播放状态 / 时间轴，没有歌词；
/// 歌词要靠壁纸自己去 lrclib / 网易云 / QQ音乐 / 酷狗 搜，B 站独占曲目经常搜不到。
///
/// 这里让 bilimusic 在本机回环地址上开一个小 HTTP 服务，把「当前正在播的曲目」
/// 连同封面图和已经匹配好的歌词一起吐出来，壁纸直接来取。
///
/// 约定：
/// · 只绑定 127.0.0.1，不对外网开放；
/// · 数据接口都要带 token，防止同机其它网页随手读取；
/// · 端口默认 47890，被占用时往后顺延最多 10 个，壁纸会按同样的范围去找。
library;

import 'dart:io';

/// 桥接协议常量。
class BridgeProtocol {  const BridgeProtocol._();

  /// 协议版本，双方都用它做兼容性判断。
  static const int version = 1;

  /// 服务标识，壁纸据此判断「连上的是不是 bilimusic」。
  static const String appName = 'bilimusic';

  /// 回环地址。只监听本机，不对外网开放。
  static const String host = '127.0.0.1';

  /// 默认端口。可用环境变量 `BILIMUSIC_BRIDGE_PORT` 固定。
  static const int defaultPort = 47890;

  /// 端口被占用时向后顺延的上限（47890..47899）。
  static const int portScanCount = 10;

  /// 数据接口的访问令牌。壁纸侧用的是同一个常量。
  static const String token = 'bilimusic-wallpaper';

  /// 当前播放曲目（JSON）。
  static const String nowPath = '/now';

  /// 当前歌词（纯文本 LRC）。
  static const String lyricsPath = '/lyrics';

  /// 当前封面图（图片二进制）。
  static const String coverPath = '/cover';

  /// 健康检查（不需要令牌）。
  static const String healthPath = '/health';

  /// 环境变量名：固定端口时用。
  static const String portEnvName = 'BILIMUSIC_BRIDGE_PORT';

  /// 构造带令牌的完整地址。
  static String url(int port, String path) {
    return 'http://$host:$port$path?k=$token';
  }

  /// 判断请求是否带对了令牌。
  static bool isAuthorized(Map<String, String> query) {
    return query['k'] == token;
  }

  /// 解析要监听的端口：环境变量优先，否则从 defaultPort 起顺延。
  static List<int> candidatePorts() {
    final String? raw = _readEnv(portEnvName);
    if (raw != null) {
      final int? parsed = int.tryParse(raw.trim());
      if (parsed != null && parsed > 0 && parsed < 65536) {
        return <int>[parsed];
      }
    }
    return <int>[
      for (int i = 0; i < portScanCount; i++) defaultPort + i,
    ];
  }

  static String? _readEnv(String name) {
    try {
      return Platform.environment[name];
    } on Object {
      return null;
    }
  }
}
