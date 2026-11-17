import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bilimusic/common/components/cached_image.dart';
import 'package:flutter/material.dart';

class CdDisc extends StatefulWidget {
  const CdDisc({
    super.key,
    required this.size,
    required this.accentColor,
    required this.isPlaying,
    this.coverUrl,
    this.coverBytes,
    this.onTap,
  });

  final double size;
  final Color accentColor;
  final bool isPlaying;
  final String? coverUrl;
  final Uint8List? coverBytes;
  final VoidCallback? onTap;

  @override
  State<CdDisc> createState() => _CdDiscState();
}

class _CdDiscState extends State<CdDisc> with SingleTickerProviderStateMixin {
  static const Duration _revolution = Duration(seconds: 16);

  late final AnimationController _controller;
  double _turnsOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _revolution);
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CdDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) {
      return;
    }
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _holdSpin();
    }
  }

  void _holdSpin() {
    _turnsOffset = (_turnsOffset + _controller.value) % 1;
    _controller
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _DiscGlow(size: size, color: widget.accentColor),
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return Transform.rotate(
                  angle: 2 * math.pi * (_turnsOffset + _controller.value),
                  child: child,
                );
              },
              child: _buildFace(),
            ),
            IgnorePointer(
              child: SizedBox(
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      transform: const GradientRotation(-0.85),
                      stops: const <double>[0, 0.18, 0.34, 0.5, 0.68, 0.86, 1],
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFace() {
    final double size = widget.size;
    final double coverSize = size * 0.66;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          stops: <double>[0, 0.36, 0.72, 1],
          colors: <Color>[
            Color(0xFFF6F9FC),
            Color(0xFFDFE6EF),
            Color(0xFFB3BECC),
            Color(0xFF7C8896),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: size * 0.10,
            offset: Offset(0, size * 0.03),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _CdGroovePainter(
                accent: widget.accentColor,
                holeFactor: 0.17,
              ),
            ),
          ),
          Container(
            width: coverSize,
            height: coverSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: size * 0.02,
                ),
              ],
            ),
            child: _buildCover(),
          ),
          Container(
            width: size * 0.17,
            height: size * 0.17,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                stops: <double>[0, 0.62, 1],
                colors: <Color>[
                  Color(0xFFE6ECF4),
                  Color(0xFFA9B4C2),
                  Color(0xFF737F8D),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: size * 0.065,
                height: size * 0.065,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF12171E).withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    final Uint8List? bytes = widget.coverBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildFallback(),
      );
    }
    final String? url = widget.coverUrl;
    if (url != null && url.trim().isNotEmpty) {
      return CommonCachedImage(imageUrl: url, fit: BoxFit.cover);
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return ColoredBox(
      color: const Color(0xFF11161D),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: widget.size * 0.16,
          color: Colors.white.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}

class _DiscGlow extends StatelessWidget {
  const _DiscGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size * 1.22,
        height: size * 1.22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            stops: const <double>[0, 0.55, 1],
            colors: <Color>[
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CdGroovePainter extends CustomPainter {
  const _CdGroovePainter({required this.accent, required this.holeFactor});

  final Color accent;
  final double holeFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outer = size.width / 2;
    final Paint ringPaint = Paint()..style = PaintingStyle.stroke;
    const int ringCount = 54;
    for (int index = 0; index < ringCount; index++) {
      final double factor = index / ringCount;
      final double radius =
          outer * (holeFactor + (0.985 - holeFactor) * factor);
      ringPaint
        ..strokeWidth = index.isEven ? 0.7 : 1.2
        ..color = Colors.white.withValues(alpha: index.isEven ? 0.05 : 0.028);
      canvas.drawCircle(center, radius, ringPaint);
    }

    final Paint accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outer * 0.03
      ..color = accent.withValues(alpha: 0.10)
      ..strokeCap = StrokeCap.round;
    final Rect arcBounds = Rect.fromCircle(
      center: center,
      radius: outer * 0.82,
    );
    canvas.drawArc(arcBounds, -2.32, 0.62, false, accentPaint);
    canvas.drawArc(arcBounds, 0.82, 0.46, false, accentPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.30);
    canvas.drawCircle(center, outer - 0.8, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _CdGroovePainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.holeFactor != holeFactor;
  }
}
