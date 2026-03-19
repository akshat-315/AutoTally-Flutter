import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSegment {
  final Color color;
  final double value;
  final String label;
  final String icon;

  const DonutSegment({
    required this.color,
    required this.value,
    required this.label,
    required this.icon,
  });
}

class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 200,
    this.strokeWidth = 28,
    this.center,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _DonutPainter(
              segments: widget.segments,
              strokeWidth: widget.strokeWidth,
              progress: _animation.value,
            ),
            child: Center(child: widget.center),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final double progress;

  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFF1A1A2E);

    canvas.drawCircle(center, radius, bgPaint);

    var startAngle = -math.pi / 2;
    final gapAngle = segments.length > 1 ? 0.03 : 0.0;

    for (final segment in segments) {
      final sweepAngle =
          (segment.value / total) * 2 * math.pi * progress - gapAngle;
      if (sweepAngle <= 0) {
        startAngle += (segment.value / total) * 2 * math.pi * progress;
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = segment.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
