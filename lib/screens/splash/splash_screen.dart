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
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoSpin;

  late AnimationController _coverController;
  late Animation<double> _leftCoverAngle;
  late Animation<double> _rightCoverAngle;
  late Animation<double> _coverShadow;

  late AnimationController _typewriterController;
  late AnimationController _fadeController;
  late Animation<double> _fadeOpacity;

  int _typedChars = 0;
  bool _showCursor = true;
  bool _coverOpened = false;
  bool _showTypewriter = false;

  static const _autoText = 'Your money, auto-tracked.';
  static const _typingDelay = Duration(milliseconds: 70);

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoSpin = Tween<double>(begin: 0, end: 3 * 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Cubic(0.4, 0, 0.2, 1),
      ),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.05), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Cubic(0.4, 0, 0.2, 1),
    ));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.15),
      ),
    );

    _coverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _leftCoverAngle = Tween<double>(begin: 0, end: -math.pi / 2).animate(
      CurvedAnimation(
        parent: _coverController,
        curve: const Cubic(0.4, 0, 0.2, 1),
      ),
    );
    _rightCoverAngle = Tween<double>(begin: 0, end: math.pi / 2).animate(
      CurvedAnimation(
        parent: _coverController,
        curve: const Cubic(0.4, 0, 0.2, 1),
      ),
    );
    _coverShadow = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _coverController,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _autoText.length * _typingDelay.inMilliseconds),
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

    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 2200));

    _coverController.forward();
    setState(() => _coverOpened = true);

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() => _showTypewriter = true);
    _typeText();

    await Future.delayed(Duration(milliseconds: _autoText.length * _typingDelay.inMilliseconds + 800));

    _startCursorBlink();

    await Future.delayed(const Duration(milliseconds: 600));

    _fadeController.forward().then((_) {
      widget.onComplete();
    });
  }

  void _typeText() async {
    for (int i = 0; i < _autoText.length; i++) {
      await Future.delayed(_typingDelay);
      if (mounted) {
        setState(() => _typedChars = i + 1);
      }
    }
  }

  void _startCursorBlink() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _showCursor = !_showCursor);
      return mounted;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _coverController.dispose();
    _typewriterController.dispose();
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
            _buildLedgerPages(),
            if (!_coverOpened) _buildClosedCover(),
            if (_coverOpened) ...[
              _buildOpeningLeftCover(),
              _buildOpeningRightCover(),
            ],
            if (_showTypewriter) _buildTypewriter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerPages() {
    return CustomPaint(
      painter: _LedgerPagesPainter(
        lineColor: AppTheme.ruled.withValues(alpha: 0.4),
        marginColor: AppTheme.inkRed.withValues(alpha: 0.15),
        spacing: 28,
      ),
    );
  }

  Widget _buildClosedCover() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Container(
          color: AppTheme.parchment,
          child: CustomPaint(
            painter: _CoverGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.04),
              density: 200,
            ),
            child: Center(
              child: Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.rotate(
                    angle: _logoSpin.value,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpeningLeftCover() {
    return AnimatedBuilder(
      animation: _coverController,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;

        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: width / 2,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(_leftCoverAngle.value),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.parchment,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkDark.withValues(alpha: 0.15),
                    blurRadius: _coverShadow.value,
                    offset: Offset(_coverShadow.value / 2, 0),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CoverGrainPainter(
                  color: AppTheme.inkDark.withValues(alpha: 0.04),
                  density: 100,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpeningRightCover() {
    return AnimatedBuilder(
      animation: _coverController,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;

        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: width / 2,
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(_rightCoverAngle.value),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.parchment,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkDark.withValues(alpha: 0.15),
                    blurRadius: _coverShadow.value,
                    offset: Offset(-_coverShadow.value / 2, 0),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CoverGrainPainter(
                  color: AppTheme.inkDark.withValues(alpha: 0.04),
                  density: 100,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypewriter() {
    final typed = _autoText.substring(0, _typedChars);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            typed,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppTheme.inkDark.withValues(alpha: 0.75),
              letterSpacing: 0.5,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _showCursor && _typedChars < _autoText.length ? 1.0 : (_showCursor ? 1.0 : 0.0),
            child: Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: 2),
              color: AppTheme.inkDark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerPagesPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double spacing;

  _LedgerPagesPainter({
    required this.lineColor,
    required this.marginColor,
    this.spacing = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = spacing; y < size.height; y += spacing) {
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
  bool shouldRepaint(covariant _LedgerPagesPainter oldDelegate) => false;
}

class _CoverGrainPainter extends CustomPainter {
  final Color color;
  final int density;

  _CoverGrainPainter({required this.color, this.density = 200});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rng = math.Random(42);

    for (int i = 0; i < density; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.5 + 0.3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CoverGrainPainter oldDelegate) =>
      color != oldDelegate.color || density != oldDelegate.density;
}
