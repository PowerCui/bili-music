import 'dart:async';

import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_lyric/flutter_lyric.dart';

class CdLyricPane extends StatefulWidget {
  const CdLyricPane({
    super.key,
    required this.nowPlaying,
    required this.playback,
    required this.accentColor,
    this.textScale = 1,
    this.onSeek,
  });

  final NowPlaying? nowPlaying;
  final NowPlayingPlayback playback;
  final Color accentColor;
  final double textScale;
  final ValueChanged<Duration>? onSeek;

  @override
  State<CdLyricPane> createState() => _CdLyricPaneState();
}

class _CdLyricPaneState extends State<CdLyricPane> {
  late final _CdLyricProgressSource _progressSource;
  late final LyricController _controller;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    _progressSource = _CdLyricProgressSource(widget.playback);
    _controller = LyricController(progressSource: _progressSource);
    _syncDocument();
  }

  @override
  void didUpdateWidget(covariant CdLyricPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progressSource.update(widget.playback);
    _syncDocument();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressSource.dispose();
    super.dispose();
  }

  void _syncDocument() {
    final NowPlaying? nowPlaying = widget.nowPlaying;
    final String lyrics = nowPlaying?.lyrics ?? '';
    if (nowPlaying == null || lyrics.isEmpty) {
      if (_loadedKey != null) {
        _loadedKey = null;
        _controller.clear();
      }
      return;
    }

    final String? translation = nowPlaying.hasTranslationLyrics
        ? nowPlaying.translationLyrics
        : null;
    final String key =
        '${nowPlaying.stableId}|${nowPlaying.lyricOffsetMs}|$translation|$lyrics';
    if (key == _loadedKey) {
      return;
    }
    _loadedKey = key;
    _controller.timeOffset = Duration(milliseconds: nowPlaying.lyricOffsetMs);
    _controller.load(lyrics, translation: translation);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nowPlaying?.hasLyrics != true) {
      return const SizedBox.expand();
    }
    return LyricView(
      controller: _controller,
      preset: _buildPreset(),
      onLineTap: (LyricLineDetails details) {
        final ValueChanged<Duration>? onSeek = widget.onSeek;
        if (onSeek == null) {
          return;
        }
        onSeek(
          details.seekPosition -
              Duration(milliseconds: widget.nowPlaying?.lyricOffsetMs ?? 0),
        );
      },
    );
  }

  LyricPreset _buildPreset() {
    const LyricPreset base = LyricPresets.appleMusic;
    final double scale = widget.textScale;
    final Color accent = widget.accentColor;
    return base.copyWith(
      textStyle: base.textStyle.copyWith(
        fontSize: 25 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.38),
      ),
      activeTextStyle: TextStyle(
        fontSize: 30 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.97),
        height: 1.24,
      ),
      translationTextStyle: base.translationTextStyle.copyWith(
        fontSize: 16 * scale,
        color: Colors.white.withValues(alpha: 0.42),
      ),
      activeTranslationTextStyle: base.activeTranslationTextStyle.copyWith(
        fontSize: 17 * scale,
        color: accent.withValues(alpha: 0.92),
      ),
      textAlign: TextAlign.center,
      contentAlignment: LyricContentAlignment.center,
      activeAnchor: LyricAnchor.fraction(
        0.42,
        target: LyricAnchorTarget.lineCenter,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      lineSpacing: 14 * scale,
      translationSpacing: 6 * scale,
      highlight: LyricHighlight.solid(
        accent,
        tailFadeWidth: base.highlight.tailFadeWidth,
      ),
      countdown: const LyricCountdown.none(),
      wordEffects: const LyricWordEffects(),
    );
  }
}

class _CdLyricProgressSource implements LyricProgressSource {
  _CdLyricProgressSource(this._playback)
    : _position = _playback.position,
      _sampledAt = SchedulerBinding.instance.currentFrameTimeStamp;

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  NowPlayingPlayback _playback;
  Duration _position;
  Duration _sampledAt;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  bool get isAdvancing =>
      _playback.hasItem &&
      _playback.isReady &&
      _playback.isPlaying &&
      !_playback.isBuffering &&
      !_playback.isLoading;

  @override
  Duration get position {
    final Duration elapsed = isAdvancing
        ? SchedulerBinding.instance.currentFrameTimeStamp - _sampledAt
        : Duration.zero;
    final Duration next =
        _position +
        Duration(microseconds: (elapsed.inMicroseconds * _playback.speed).round());
    final Duration? duration = _playback.duration;
    return duration != null && next > duration ? duration : next;
  }

  void update(NowPlayingPlayback playback) {
    if (_playback == playback) {
      return;
    }
    _position =
        _playback.position != playback.position ||
            _playback.isPlaying != playback.isPlaying
        ? playback.position
        : position;
    _playback = playback;
    _sampledAt = SchedulerBinding.instance.currentFrameTimeStamp;
    _changes.add(null);
  }

  void dispose() => unawaited(_changes.close());
}
