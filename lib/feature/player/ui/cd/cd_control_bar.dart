import 'package:bilimusic/feature/player/domain/now_playing.dart';
import 'package:flutter/material.dart';

class CdControlBar extends StatelessWidget {
  const CdControlBar({
    super.key,
    required this.playback,
    required this.accentColor,
    this.onTogglePlayback,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.compact = false,
  });

  final NowPlayingPlayback playback;
  final Color accentColor;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CdProgressTrack(
          playback: playback,
          accentColor: accentColor,
          onSeek: onSeek,
        ),
        SizedBox(height: compact ? 10 : 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: playback.hasPrevious ? onPrevious : null,
              tooltip: '上一首',
              iconSize: compact ? 26 : 30,
              color: Colors.white.withValues(alpha: 0.88),
              disabledColor: Colors.white.withValues(alpha: 0.24),
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            SizedBox(width: compact ? 12 : 20),
            _CdPlayButton(
              isPlaying: playback.isPlaying,
              isBusy: playback.isBuffering || playback.isLoading,
              accentColor: accentColor,
              size: compact ? 54 : 64,
              onTap: playback.hasItem ? onTogglePlayback : null,
            ),
            SizedBox(width: compact ? 12 : 20),
            IconButton(
              onPressed: playback.hasNext ? onNext : null,
              tooltip: '下一首',
              iconSize: compact ? 26 : 30,
              color: Colors.white.withValues(alpha: 0.88),
              disabledColor: Colors.white.withValues(alpha: 0.24),
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _CdProgressTrack extends StatelessWidget {
  const _CdProgressTrack({
    required this.playback,
    required this.accentColor,
    required this.onSeek,
  });

  final NowPlayingPlayback playback;
  final Color accentColor;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final Duration? duration = playback.duration;
    final bool seekable =
        onSeek != null && duration != null && duration > Duration.zero;
    final TextStyle style = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: Colors.white.withValues(alpha: 0.56),
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: seekable
                  ? (TapDownDetails details) => _seek(
                      details.localPosition.dx,
                      width,
                    )
                  : null,
              onHorizontalDragUpdate: seekable
                  ? (DragUpdateDetails details) => _seek(
                      details.localPosition.dx,
                      width,
                    )
                  : null,
              child: SizedBox(
                height: 20,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: playback.progress,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                accentColor.withValues(alpha: 0.72),
                                Colors.white.withValues(alpha: 0.94),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(
                          playback.progress * 2 - 1,
                          double.infinity,
                        ),
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.65),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: <Widget>[
              Text(_formatDuration(playback.position), style: style),
              const Spacer(),
              Text(_formatDuration(duration), style: style),
            ],
          ),
        ),
      ],
    );
  }

  void _seek(double dx, double width) {
    final ValueChanged<Duration>? handler = onSeek;
    final Duration? duration = playback.duration;
    if (handler == null || duration == null || width <= 0) {
      return;
    }
    final double ratio = (dx / width).clamp(0.0, 1.0);
    handler(
      Duration(milliseconds: (duration.inMilliseconds * ratio).round()),
    );
  }
}

class _CdPlayButton extends StatelessWidget {
  const _CdPlayButton({
    required this.isPlaying,
    required this.isBusy,
    required this.accentColor,
    required this.size,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isBusy;
  final Color accentColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.96),
              accentColor.withValues(alpha: 0.92),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accentColor.withValues(alpha: 0.45),
              blurRadius: size * 0.42,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? SizedBox(
                  width: size * 0.34,
                  height: size * 0.34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF12171E).withValues(alpha: 0.72),
                    ),
                  ),
                )
              : Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: size * 0.52,
                  color: const Color(0xFF0E1319),
                ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration? value) {
  final Duration duration = value ?? Duration.zero;
  final int totalSeconds = duration.inSeconds;
  final String minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
