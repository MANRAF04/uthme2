import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Signature element of the grades screen: the ECTS-weighted average rendered
/// as a coral-to-amber ring gauge on the 0-10 scale. The arc and the number
/// animate up from zero when the widget first appears. Set [animate] to false
/// for a static render (e.g. the home-screen widget image), where the gauge
/// must show the final value in a single frame.
class GradeRing extends StatelessWidget {
  final double value;
  final double size;
  final bool animate;

  const GradeRing({
    super.key,
    required this.value,
    this.size = 116,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 10.0);

    if (!animate) return _ring(clamped);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => _ring(animated),
    );
  }

  Widget _ring(double shown) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(shown / 10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shown.toStringAsFixed(2),
                style: monoStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '/ 10',
                style: monoStyle(
                  fontSize: size * 0.095,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    const startAngle = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [AppColors.coral, AppColors.amberArc, AppColors.amber],
        stops: [0.0, 0.6, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, 2 * math.pi * progress, false, arc);

    // Pin the starting cap to a fixed coral. The sweep gradient wraps around,
    // so the rounded start cap would otherwise pick up the amber end colour;
    // drawing a coral dot over the exact start keeps the first pixel fixed.
    final startPoint = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );
    final startCap = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.coral;
    canvas.drawCircle(startPoint, stroke / 2, startCap);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
