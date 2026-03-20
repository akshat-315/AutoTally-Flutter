import 'dart:math' as math;
import 'package:flutter/material.dart';

class PageTearClipper extends CustomClipper<Path> {
  final double progress;
  final List<double> jaggedOffsets;

  PageTearClipper({required this.progress, required this.jaggedOffsets});

  @override
  Path getClip(Size size) {
    if (progress <= 0.0) return Path()..addRect(Offset.zero & size);
    if (progress >= 1.0) return Path();

    final w = size.width;
    final h = size.height;

    final k = 2.0 * (1.0 - progress);

    final path = Path();

    if (k >= 2.0) {
      path.addRect(Offset.zero & size);
      return path;
    }

    if (k > 1.0) {
      final rightY = (k - 1.0) * h;
      final bottomX = (k - 1.0) * w;

      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, rightY);

      _addJaggedLine(path, w, rightY, bottomX, h, size);

      path.lineTo(0, h);
      path.close();
    } else if (k > 0.0) {
      final topX = k * w;
      final leftY = k * h;

      path.moveTo(0, 0);
      path.lineTo(topX, 0);

      _addJaggedLine(path, topX, 0, 0, leftY, size);

      path.close();
    }

    return path;
  }

  void _addJaggedLine(
    Path path,
    double startX,
    double startY,
    double endX,
    double endY,
    Size size,
  ) {
    final steps = jaggedOffsets.length;
    final dx = endX - startX;
    final dy = endY - startY;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final perpX = -dy / length;
    final perpY = dx / length;

    final maxJag = math.min(size.width, size.height) * 0.02;

    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final x = startX + dx * t + perpX * jaggedOffsets[i] * maxJag;
      final y = startY + dy * t + perpY * jaggedOffsets[i] * maxJag;
      path.lineTo(x, y);
    }

    path.lineTo(endX, endY);
  }

  @override
  bool shouldReclip(PageTearClipper oldClipper) =>
      progress != oldClipper.progress;
}

class TearShadowPainter extends CustomPainter {
  final double progress;
  final List<double> jaggedOffsets;

  TearShadowPainter({required this.progress, required this.jaggedOffsets});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final w = size.width;
    final h = size.height;
    final k = 2.0 * (1.0 - progress);

    double startX, startY, endX, endY;

    if (k > 1.0) {
      startX = w;
      startY = (k - 1.0) * h;
      endX = (k - 1.0) * w;
      endY = h;
    } else if (k > 0.0) {
      startX = k * w;
      startY = 0;
      endX = 0;
      endY = k * h;
    } else {
      return;
    }

    final dx = endX - startX;
    final dy = endY - startY;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final perpX = -dy / length;
    final perpY = dx / length;
    final maxJag = math.min(w, h) * 0.02;

    final shadowPath = Path();
    shadowPath.moveTo(startX, startY);

    final steps = jaggedOffsets.length;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final x = startX + dx * t + perpX * jaggedOffsets[i] * maxJag;
      final y = startY + dy * t + perpY * jaggedOffsets[i] * maxJag;
      shadowPath.lineTo(x, y);
    }
    shadowPath.lineTo(endX, endY);

    final shadowOffset = 8.0 * progress;
    final offsetPath = shadowPath.shift(Offset(perpX * shadowOffset, perpY * shadowOffset));

    canvas.drawPath(
      offsetPath,
      Paint()
        ..color = const Color(0xFF2C2416).withValues(alpha: 0.12 * progress)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(TearShadowPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

List<double> generateJaggedOffsets({int steps = 40, int seed = 42}) {
  final rng = math.Random(seed);
  return List.generate(steps, (_) => (rng.nextDouble() * 2 - 1));
}
