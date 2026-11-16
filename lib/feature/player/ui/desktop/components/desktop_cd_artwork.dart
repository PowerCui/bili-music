import 'dart:math' as math;

import 'package:bilimusic/common/components/cached_image.dart';
import 'package:flutter/material.dart';

/// 唱片模式下的盘面：封面印在盘上，播放时缓缓旋转，中心留出轮毂孔。
///
/// 视觉语言对齐「麻匪 交互CD光盘」壁纸的 CD 面：盘面银底、封面为芯、
/// 一圈圈细反光纹路 + 高光扫过，暂停时停在当前角度。
class DesktopCdArtwork extends StatefulWidget {
  const DesktopCdArtwork({
    super.key,
    required this.coverUrl,
    required this.isPlaying,
    this.size = 300,
  });

  final String coverUrl;
  final bool isPlaying;
  final double size;

  @override
  State<DesktopCdArtwork> createState() => _DesktopCdArtworkState();
}

class _DesktopCdArtworkState extends State<DesktopCdArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant DesktopCdArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  void _syncPlayback() {
    if (widget.isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: child,
        );
      },
      child: _Disc(size: widget.size, coverUrl: widget.coverUrl),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.coverUrl});

  final double size;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.22, -0.26),
          radius: 1.08,
          colors: <Color>[
            Color(0xFFE9EDF3),
            Color(0xFFB9C2CF),
            Color(0xFF8B96A6),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 封面：印在盘面芯部，四周留一圈银边。
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: size * 0.72,
                height: size * 0.72,
                child: ClipOval(
                  child: CommonCachedImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.music_note_rounded,
                    iconSize: size * 0.22,
                    iconColor: colorScheme.primary.withValues(alpha: 0.58),
                    backgroundGradient: LinearGradient(
                      colors: <Color>[
                        colorScheme.primary.withValues(alpha: 0.20),
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.66,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 数据面细纹：一圈圈同心环，让盘面有「刻录区」的层次。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                  stops: const <double>[0.55, 0.56, 1.0],
                ),
              ),
            ),
          ),
          // 高光扫过：固定在盘面左上，旋转时像灯光反射。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.36, -0.42),
                  radius: 0.72,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.28, 1.0],
                ),
              ),
            ),
          ),
          // 轮毂孔。
          Container(
            width: size * 0.14,
            height: size * 0.14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.28),
                width: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
