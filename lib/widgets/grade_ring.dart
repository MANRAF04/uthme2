import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The overall average on the 0-10 scale as a coral to amber ring gauge.
/// Animates from its current value whenever [value] changes (first appearance
/// starts from zero). Set [animate] to false for a single frame render, e.g.
/// the home screen widget image.
class GradeRing extends StatelessWidget {
  final double value;
  final double size;
  final bool animate;
  final Color textColor;
  final Color secondaryTextColor;
  final Color trackColor;

  const GradeRing({
    super.key,
    required this.value,
    required this.textColor,
    required this.secondaryTextColor,
    required this.trackColor,
    this.size = 116,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 10.0);

    if (!animate || MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return _ring(clamped);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => _ring(animated),
    );
  }

  Widget _ring(double shown) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(shown / 10, trackColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shown.toStringAsFixed(2),
                style: figures(
                  TextStyle(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -size * 0.008,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                '/ 10',
                style: figures(
                  TextStyle(
                    fontSize: size * 0.1,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
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
  final Color trackColor;

  _RingPainter(this.progress, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    const startAngle = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
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
        colors: AppColors.ringGradient,
        stops: [0.0, 0.6, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(rect);

    canvas.drawArc(rect, startAngle, 2 * math.pi * progress, false, arc);

    // The sweep gradient wraps around, so the rounded start cap would pick up
    // the amber end colour; a coral dot over the start keeps it fixed.
    final startPoint = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );
    canvas.drawCircle(startPoint, stroke / 2, Paint()..color = AppColors.coral);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.trackColor != trackColor;
}
