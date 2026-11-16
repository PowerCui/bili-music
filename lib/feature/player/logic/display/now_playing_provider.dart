import 'package:bilimusic/common/util/player_util.dart';
import 'package:bilimusic/feature/metadata/domain/metadata.dart';
import 'package:bilimusic/feature/metadata/logic/metadata_controller.dart';
import 'package:bilimusic/feature/player/domain/bili_subtitle.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';
import 'package:bilimusic/feature/player/domain/player_display_info.dart';
import 'package:bilimusic/feature/player/domain/player_subtitle_state.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_metadata.dart';
import 'package:bilimusic/feature/player/logic/display/player_display_provider.dart';
import 'package:bilimusic/feature/player/logic/lyrics/player_subtitle_controller.dart';
import 'package:bilimusic/feature/player/logic/player_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'now_playing_provider.g.dart';

@riverpod
NowPlaying? nowPlaying(Ref ref) {
  final PlayableItem? item = ref.watch(
    playerControllerProvider.select((state) => state.currentItem),
  );
  if (item == null) {
    return null;
  }

  final Duration? duration = ref.watch(
    playerControllerProvider.select((state) => state.duration),
  );
  final String? sourceLabel = ref.watch(
    playerControllerProvider.select((state) => state.queueSourceLabel),
  );
  final PlayerDisplayInfo display = ref.watch(playerDisplayProvider);
  final Metadata? metadata = ref.watch(
    metadataControllerProvider.select(
      (state) => state.stableId == item.stableId ? state.metadata : null,
    ),
  );
  final PlayerSubtitleState subtitleState = ref.watch(
    playerSubtitleControllerProvider.select(
      (state) =>
          state.stableId == item.stableId ? state : const PlayerSubtitleState(),
    ),
  );

  final bool usesSubtitles = subtitleState.usesSubtitles;
  final String? lyrics = usesSubtitles
      ? _buildSubtitleLyrics(subtitleState.lines)
      : PlayerUtil.buildRenderableLyrics(
          resolveDisplayLyrics(metadata),
          duration,
        );

  return NowPlaying(
    stableId: item.stableId,
    title: _firstNonEmpty(<String?>[display.title, item.pageTitle, item.title]),
    artist: _firstNonEmpty(<String?>[display.artist, item.author]),
    coverUrl: _nullableText(display.coverUrl) ?? _nullableText(item.coverUrl),
    lyrics: _nullableText(lyrics),
    translationLyrics: usesSubtitles
        ? null
        : _nullableText(resolveDisplayTranslationLyrics(metadata)),
    lyricOffsetMs: usesSubtitles
        ? subtitleState.offsetMs
        : resolveDisplayLyricOffsetMs(metadata),
    duration: duration,
    sourceLabel: _nullableText(sourceLabel),
  );
}

@riverpod
NowPlayingPlayback nowPlayingPlayback(Ref ref) {
  return ref.watch(
    playerControllerProvider.select(
      (state) => NowPlayingPlayback(
        position: state.position,
        duration: state.duration,
        isPlaying: state.isPlaying,
        isReady: state.isReady,
        isBuffering: state.isBuffering,
        isLoading: state.isLoading,
        speed: state.speed,
        hasPrevious: state.hasPrevious,
        hasNext: state.hasNext,
        hasItem: state.hasItem,
      ),
    ),
  );
}

String _buildSubtitleLyrics(List<BiliSubtitleLine> lines) {
  final StringBuffer buffer = StringBuffer();
  for (final BiliSubtitleLine line in lines) {
    final String text = line.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      continue;
    }
    final int startMs = line.startMs < 0 ? 0 : line.startMs;
    final String minutes = (startMs ~/ 60000).toString().padLeft(2, '0');
    final String seconds = ((startMs % 60000) ~/ 1000).toString().padLeft(
      2,
      '0',
    );
    final String centiseconds = ((startMs % 1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    buffer.writeln('[$minutes:$seconds.$centiseconds]$text');
  }
  return buffer.toString();
}

String _firstNonEmpty(List<String?> values) {
  for (final String? value in values) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

String? _nullableText(String? value) {
  final String trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
