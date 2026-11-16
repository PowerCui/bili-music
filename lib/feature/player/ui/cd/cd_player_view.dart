import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bilimusic/common/components/cached_image.dart';
import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_control_bar.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_disc.dart';
import 'package:bilimusic/feature/player/ui/cd/cd_lyric_pane.dart';
import 'package:flutter/material.dart';

class CdPlayerView extends StatelessWidget {
  const CdPlayerView({
    super.key,
    required this.nowPlaying,
    required this.playback,
    required this.accentColor,
    this.coverBytes,
    this.onTogglePlayback,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.showLyrics = true,
    this.padding = const EdgeInsets.all(32),
  });

  final NowPlaying? nowPlaying;
  final NowPlayingPlayback playback;
  final Color accentColor;
  final Uint8List? coverBytes;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;
  final bool showLyrics;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildCdTheme(accentColor),
      child: Builder(
        builder: (BuildContext themedContext) {
          final NowPlaying? item = nowPlaying;
          return DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF07090C)),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _CdBackdrop(
                  accentColor: accentColor,
                  coverUrl: item?.coverUrl,
                  coverBytes: coverBytes,
                ),
                SafeArea(
                  child: Padding(
                    padding: padding,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            if (item == null) {
                              return _CdEmptyState(
                                accentColor: accentColor,
                                textStyle: Theme.of(context).textTheme,
                              );
                            }
                            return _CdLayout(
                              nowPlaying: item,
                              playback: playback,
                              accentColor: accentColor,
                              coverBytes: coverBytes,
                              constraints: constraints,
                              onTogglePlayback: onTogglePlayback,
                              onPrevious: onPrevious,
                              onNext: onNext,
                              onSeek: onSeek,
                              showLyrics: showLyrics,
                            );
                          },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

ThemeData buildCdTheme(Color accentColor) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: Brightness.dark,
  ).copyWith(surface: const Color(0xFF07090C));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    splashFactory: NoSplash.splashFactory,
  );
}

class _CdLayout extends StatelessWidget {
  const _CdLayout({
    required this.nowPlaying,
    required this.playback,
    required this.accentColor,
    required this.coverBytes,
    required this.constraints,
    required this.onTogglePlayback,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.showLyrics,
  });

  final NowPlaying nowPlaying;
  final NowPlayingPlayback playback;
  final Color accentColor;
  final Uint8List? coverBytes;
  final BoxConstraints constraints;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;
  final bool showLyrics;

  @override
  Widget build(BuildContext context) {
    final bool wide =
        constraints.maxWidth >= 720 &&
        constraints.maxWidth > constraints.maxHeight;
    if (wide) {
      return _buildWide(context);
    }
    return _buildNarrow(context);
  }

  Widget _buildWide(BuildContext context) {
    final double discSize = math
        .min(constraints.maxHeight * 0.58, constraints.maxWidth * 0.34)
        .clamp(190, 520)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CdDisc(
                size: discSize,
                accentColor: accentColor,
                isPlaying: playback.isPlaying,
                coverUrl: nowPlaying.coverUrl,
                coverBytes: coverBytes,
                onTap: onTogglePlayback,
              ),
              SizedBox(height: discSize * 0.09),
              _CdMeta(nowPlaying: nowPlaying, alignment: TextAlign.center),
              SizedBox(height: discSize * 0.09),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: discSize * 1.15),
                child: CdControlBar(
                  playback: playback,
                  accentColor: accentColor,
                  onTogglePlayback: onTogglePlayback,
                  onPrevious: onPrevious,
                  onNext: onNext,
                  onSeek: onSeek,
                ),
              ),
            ],
          ),
        ),
        if (showLyrics && nowPlaying.hasLyrics)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CdLyricPane(
                nowPlaying: nowPlaying,
                playback: playback,
                accentColor: accentColor,
                onSeek: onSeek,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final double discSize = math
        .min(constraints.maxWidth * 0.62, constraints.maxHeight * 0.36)
        .clamp(140, 380)
        .toDouble();
    return Column(
      children: <Widget>[
        const Spacer(),
        CdDisc(
          size: discSize,
          accentColor: accentColor,
          isPlaying: playback.isPlaying,
          coverUrl: nowPlaying.coverUrl,
          coverBytes: coverBytes,
          onTap: onTogglePlayback,
        ),
        SizedBox(height: discSize * 0.11),
        _CdMeta(nowPlaying: nowPlaying, alignment: TextAlign.center),
        if (showLyrics && nowPlaying.hasLyrics)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CdLyricPane(
                nowPlaying: nowPlaying,
                playback: playback,
                accentColor: accentColor,
                textScale: 0.82,
                onSeek: onSeek,
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(height: 8),
        CdControlBar(
          playback: playback,
          accentColor: accentColor,
          onTogglePlayback: onTogglePlayback,
          onPrevious: onPrevious,
          onNext: onNext,
          onSeek: onSeek,
          compact: true,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CdMeta extends StatelessWidget {
  const _CdMeta({required this.nowPlaying, required this.alignment});

  final NowPlaying nowPlaying;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignment == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          nowPlaying.title,
          textAlign: alignment,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white.withValues(alpha: 0.96),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nowPlaying.artist,
          textAlign: alignment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            letterSpacing: 0.3,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _CdBackdrop extends StatelessWidget {
  const _CdBackdrop({
    required this.accentColor,
    required this.coverUrl,
    required this.coverBytes,
  });

  final Color accentColor;
  final String? coverUrl;
  final Uint8List? coverBytes;

  @override
  Widget build(BuildContext context) {
    final Widget? cover = _buildCover();
    final Color deep = Color.lerp(accentColor, const Color(0xFF05070A), 0.82)!;
    final Color mid = Color.lerp(accentColor, const Color(0xFF05070A), 0.62)!;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[mid, deep, const Color(0xFF05070A)],
              ),
            ),
          ),
          if (cover != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 52,
                  sigmaY: 52,
                  tileMode: TileMode.clamp,
                ),
                child: Opacity(opacity: 0.34, child: cover),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.05, -0.4),
                radius: 0.95,
                colors: <Color>[
                  accentColor.withValues(alpha: 0.34),
                  accentColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  const Color(0xFF05070A).withValues(alpha: 0.55),
                  const Color(0xFF05070A).withValues(alpha: 0.12),
                  const Color(0xFF05070A).withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildCover() {
    final Uint8List? bytes = coverBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
    }
    final String? url = coverUrl;
    if (url != null && url.trim().isNotEmpty) {
      return CommonCachedImage(imageUrl: url, fit: BoxFit.cover);
    }
    return null;
  }
}

class _CdEmptyState extends StatelessWidget {
  const _CdEmptyState({required this.accentColor, required this.textStyle});

  final Color accentColor;
  final TextTheme textStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.album_rounded,
            size: 64,
            color: accentColor.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text('未在播放', style: textStyle.titleMedium),
        ],
      ),
    );
  }
}
