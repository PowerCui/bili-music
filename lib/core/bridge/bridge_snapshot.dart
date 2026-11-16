import 'package:bilimusic/core/bridge/bridge_protocol.dart';

/// 一次采样得到的「当前正在播的曲目」快照。
///
/// 这份结构就是桥接的对外契约，壁纸按同样的字段名解析。
class BridgeSnapshot {
  const BridgeSnapshot({
    required this.active,
    required this.playing,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.position,
    required this.duration,
    required this.lyrics,
    required this.lyricsSource,
    required this.lyricsOffsetMs,
    required this.updatedAtMs,
  });

  /// 当前没有可播的内容（应用刚启动、或用户停了）。
  const BridgeSnapshot.empty()
    : active = false,
      playing = false,
      title = '',
      artist = '',
      album = '',
      coverUrl = null,
      position = 0,
      duration = 0,
      lyrics = '',
      lyricsSource = 'none',
      lyricsOffsetMs = 0,
      updatedAtMs = 0;

  /// 是否有正在播的曲目。
  final bool active;

  /// 是否处于播放中（暂停时为 false）。
  final bool playing;

  /// 歌名。
  final String title;

  /// 歌手 / UP 主。
  final String artist;

  /// 专辑（这里放播放队列来源）。
  final String album;

  /// 上游封面地址（可能是 B 站图床，壁纸不能直接加载，需要走 /cover 代理）。
  final String? coverUrl;

  /// 播放位置（秒）。
  final double position;

  /// 总时长（秒）。
  final double duration;

  /// 歌词正文（LRC，或没有时间轴的纯文本）。
  final String lyrics;

  /// 歌词来源：meting / subtitle / none。
  final String lyricsSource;

  /// 歌词时间偏移（毫秒）。
  ///
  /// 用的是**壁纸那边**的约定：正值 = 歌词整体延后出现。
  /// bilimusic 内部的约定正好相反（正值 = 歌词提前出现），
  /// 所以这里在导出时已经取过反，两边对同一个数值的理解是一致的。
  final int lyricsOffsetMs;

  /// 采样时刻（毫秒时间戳）。
  final int updatedAtMs;

  /// 歌词内容指纹。壁纸用它判断「歌词是不是换了一首」。
  String get lyricsToken => _hash(lyrics);

  /// 封面指纹。壁纸用它判断「封面是不是换了」。
  String get coverToken => _hash(coverUrl ?? '');

  /// 序列化成壁纸要读的 JSON。
  Map<String, dynamic> toJson(int port) {
    final String? cover = coverUrl == null || coverUrl!.trim().isEmpty
        ? null
        : 'http://${BridgeProtocol.host}:$port${BridgeProtocol.coverPath}'
              '?k=${BridgeProtocol.token}&v=$coverToken';
    return <String, dynamic>{
      'v': BridgeProtocol.version,
      'app': BridgeProtocol.appName,
      'active': active,
      'playing': playing,
      'title': title,
      'artist': artist,
      'album': album,
      'cover': cover,
      'coverToken': coverToken,
      'position': position,
      'duration': duration,
      'lyricsToken': lyricsToken,
      'lyricsSource': lyricsSource,
      'lyricsOffsetMs': lyricsOffsetMs,
      'updatedAt': updatedAtMs,
    };
  }

  /// 稳定的字符串指纹（FNV-1a 32 位），跨进程一致。
  static String _hash(String value) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < value.length; i++) {
      hash ^= value.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
