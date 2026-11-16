import 'package:freezed_annotation/freezed_annotation.dart';

part 'now_playing.freezed.dart';

@freezed
abstract class NowPlaying with _$NowPlaying {
  const NowPlaying._();

  const factory NowPlaying({
    required String stableId,
    required String title,
    required String artist,
    String? coverUrl,
    String? lyrics,
    String? translationLyrics,
    @Default(0) int lyricOffsetMs,
    Duration? duration,
    String? sourceLabel,
  }) = _NowPlaying;

  bool get hasLyrics => lyrics != null && lyrics!.trim().isNotEmpty;

  bool get hasTranslationLyrics =>
      translationLyrics != null && translationLyrics!.trim().isNotEmpty;
}

@freezed
abstract class NowPlayingPlayback with _$NowPlayingPlayback {
  const NowPlayingPlayback._();

  const factory NowPlayingPlayback({
    @Default(Duration.zero) Duration position,
    Duration? duration,
    @Default(false) bool isPlaying,
    @Default(false) bool isReady,
    @Default(false) bool isBuffering,
    @Default(false) bool isLoading,
    @Default(1) double speed,
    @Default(false) bool hasPrevious,
    @Default(false) bool hasNext,
    @Default(true) bool hasItem,
  }) = _NowPlayingPlayback;

  bool get canAdvance =>
      isReady && !isBuffering && !isLoading && hasItem && !isPlaying;

  double get progress {
    final Duration? total = duration;
    if (total == null || total <= Duration.zero) {
      return 0;
    }
    return (position.inMilliseconds / total.inMilliseconds).clamp(0, 1);
  }
}
