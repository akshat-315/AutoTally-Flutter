import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _strokeController;
  late AnimationController _fadeController;

  late Animation<double> _inkDotOpacity;
  late Animation<double> _logoReveal;
  late Animation<double> _logoScale;
  late Animation<double> _taglineReveal;
  late Animation<double> _fadeOpacity;

  @override
  void initState() {
    super.initState();

    _strokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _inkDotOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(0.0, 0.1, curve: Curves.easeOut),
      ),
    );

    _logoReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
      ),
    );

    _taglineReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _strokeController,
        curve: const Interval(0.42, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _strokeController.forward();

    await Future.delayed(const Duration(milliseconds: 2400));

    _fadeController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _strokeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeOpacity.value,
          child: child,
        );
      },
      child: Material(
        color: AppTheme.parchmentLight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ParchmentGrainPainter(
                lineColor: AppTheme.ruled.withValues(alpha: 0.4),
                marginColor: AppTheme.inkRed.withValues(alpha: 0.15),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _strokeController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInkDot(),
                      _buildLogo(),
                      const SizedBox(height: 14),
                      _buildTagline(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInkDot() {
    final opacity = _inkDotOpacity.value;
    final shrink = _logoReveal.value.clamp(0.0, 1.0);
    final dotSize = 4.0 * (1 - shrink * 0.8);

    if (opacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity * (1 - shrink).clamp(0.3, 1.0),
      child: Container(
        width: dotSize,
        height: dotSize,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppTheme.inkDark.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkDark.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final reveal = _logoReveal.value;
    final scale = _logoScale.value;

    return Transform.scale(
      scale: scale,
      child: ShaderMask(
        shaderCallback: (bounds) {
          final leadingEdge = reveal * 1.3;
          final trailingEdge = (reveal * 1.3 - 0.3).clamp(0.0, 1.0);

          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: [
              0.0,
              trailingEdge,
              leadingEdge.clamp(0.0, 1.0),
              (leadingEdge + 0.05).clamp(0.0, 1.0),
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    final reveal = _taglineReveal.value;

    if (reveal <= 0) return const SizedBox(height: 24);

    return ShaderMask(
      shaderCallback: (bounds) {
        final leadingEdge = reveal * 1.25;
        final trailingEdge = (reveal * 1.25 - 0.25).clamp(0.0, 1.0);

        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white,
            Colors.white,
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: [
            0.0,
            trailingEdge,
            leadingEdge.clamp(0.0, 1.0),
            (leadingEdge + 0.04).clamp(0.0, 1.0),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Text(
        'Your money, auto-tracked.',
        style: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: AppTheme.inkDark.withValues(alpha: 0.75),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ParchmentGrainPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;

  _ParchmentGrainPainter({
    required this.lineColor,
    required this.marginColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(40, 0),
      Offset(40, size.height),
      marginPaint,
    );

    final grainPaint = Paint()..color = lineColor.withValues(alpha: 0.15);
    final rng = math.Random(99);
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.0 + 0.2, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParchmentGrainPainter oldDelegate) => false;
}
