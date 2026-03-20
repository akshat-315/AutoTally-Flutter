import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/widgets/page_tear_clipper.dart';
import 'package:autotally_flutter/repositories/app_config_repository.dart';
import 'package:autotally_flutter/repositories/transaction_repository.dart';
import 'package:autotally_flutter/services/sms_reader/sms_reader_service.dart';
import 'package:autotally_flutter/services/sms_parser/template_engine.dart';
import 'package:autotally_flutter/services/merchant_resolver/merchant_resolver.dart';
import 'package:autotally_flutter/main.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  bool _isAnimating = false;
  late AnimationController _tearController;
  late List<double> _jaggedOffsets;

  bool _permissionDenied = false;
  bool _permanentlyDenied = false;

  String _scanPhase = 'reading';
  int _totalFinancialSms = 0;
  int _processedSms = 0;
  int _matchedSms = 0;
  int _savedCount = 0;
  int _banksFound = 0;
  bool _scanComplete = false;

  @override
  void initState() {
    super.initState();
    _jaggedOffsets = generateJaggedOffsets(steps: 50);
    _tearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tearController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentPage++;
          _isAnimating = false;
          _tearController.reset();
        });
        if (_currentPage == 3) {
          _startSmsScan();
        }
      }
    });
  }

  void _nextPage() {
    if (_isAnimating || _currentPage >= 3) return;
    setState(() => _isAnimating = true);
    _jaggedOffsets = generateJaggedOffsets(
      steps: 50,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    _tearController.forward();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      setState(() {
        _permissionDenied = false;
        _permanentlyDenied = false;
      });
      _nextPage();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
        _permanentlyDenied = true;
      });
    } else {
      setState(() {
        _permissionDenied = true;
        _permanentlyDenied = false;
      });
    }
  }

  Future<void> _startSmsScan() async {
    final engine = TemplateEngine(database);
    final resolver = MerchantResolver(database);
    final reader = SmsReaderService(engine, resolver);
    final txRepo = TransactionRepository(database);
    final configRepo = AppConfigRepository(database);

    try {
      final result = await reader.readAndParseAll(
        onProgress: ({
          required int total,
          required int processed,
          required int matched,
          required String phase,
        }) {
          if (mounted) {
            setState(() {
              _scanPhase = phase;
              _totalFinancialSms = total;
              _processedSms = processed;
              _matchedSms = matched;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _scanPhase = 'saving';
          _banksFound = result.parsed.map((t) => t.data.bank).toSet().length;
        });
      }

      var saved = 0;
      for (final tx in result.parsed) {
        final id = await txRepo.saveTransaction(tx);
        if (id != null) saved++;
        if (mounted) {
          setState(() => _savedCount = saved);
        }
      }

      await configRepo.setBool('onboarding_complete', true);

      if (mounted) {
        setState(() => _scanComplete = true);
        await Future.delayed(const Duration(milliseconds: 1800));
        widget.onComplete();
      }
    } catch (e) {
      await configRepo.setBool('onboarding_complete', true);
      if (mounted) {
        setState(() => _scanComplete = true);
        await Future.delayed(const Duration(milliseconds: 1000));
        widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _tearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.parchmentLight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _OnboardingParchmentPainter(),
          ),
          _buildPage(_currentPage == 3 ? 3 : math.min(_currentPage + 1, 3)),
          if (_isAnimating)
            AnimatedBuilder(
              animation: _tearController,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: TearShadowPainter(
                        progress: _tearController.value,
                        jaggedOffsets: _jaggedOffsets,
                      ),
                    ),
                    ClipPath(
                      clipper: PageTearClipper(
                        progress: _tearController.value,
                        jaggedOffsets: _jaggedOffsets,
                      ),
                      child: child,
                    ),
                  ],
                );
              },
              child: _buildPage(_currentPage),
            ),
          if (!_isAnimating && _currentPage < 3)
            _buildPage(_currentPage),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _WelcomePage(onNext: _nextPage);
      case 1:
        return _PrivacyPage(onNext: _nextPage);
      case 2:
        return _PermissionPage(
          onGrant: _requestPermission,
          denied: _permissionDenied,
          permanentlyDenied: _permanentlyDenied,
        );
      case 3:
        return _ProcessingPage(
          phase: _scanPhase,
          totalFinancial: _totalFinancialSms,
          processed: _processedSms,
          matched: _matchedSms,
          saved: _savedCount,
          banksFound: _banksFound,
          scanComplete: _scanComplete,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      pageIndex: 0,
      onNext: onNext,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 88,
            height: 88,
          ),
          const SizedBox(height: 32),
          Text(
            'AutoTally',
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your bank sends an SMS for every\ntransaction. AutoTally reads them and\nturns them into a spending tracker\n— automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.inkFaded,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Your money, auto-tracked.',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppTheme.inkDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  final VoidCallback onNext;

  const _PrivacyPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      pageIndex: 1,
      onNext: onNext,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 56,
            color: AppTheme.inkDark.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 28),
          Text(
            'A Promise, In Ink',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Everything stays on your phone.\nNo accounts. No servers. No ads.\nYour data never leaves your device.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.inkFaded,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _buildPromiseItem('No sign-up required'),
          const SizedBox(height: 12),
          _buildPromiseItem('No internet needed'),
          const SizedBox(height: 12),
          _buildPromiseItem('No data ever uploaded'),
          const SizedBox(height: 12),
          _buildPromiseItem('Works fully offline, forever'),
        ],
      ),
    );
  }

  Widget _buildPromiseItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.inkDark.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.lora(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.inkDark.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final VoidCallback onGrant;
  final bool denied;
  final bool permanentlyDenied;

  const _PermissionPage({
    required this.onGrant,
    this.denied = false,
    this.permanentlyDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      pageIndex: 2,
      showNextButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sms_outlined,
            size: 56,
            color: AppTheme.inkDark.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 28),
          Text(
            'One Permission',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkDark,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AutoTally needs to read SMS to find\nbank transactions. Only financial\nmessages are processed — nothing\nis stored beyond your phone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.inkFaded,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: permanentlyDenied ? () => openAppSettings() : onGrant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.inkDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                permanentlyDenied ? 'Open Settings' : 'Grant SMS Access',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.parchmentLight,
                ),
              ),
            ),
          ),
          if (denied) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                permanentlyDenied
                    ? 'Permission was denied permanently. Please enable SMS access in your phone\'s app settings.'
                    : 'SMS access is essential for AutoTally to work. Without it, there are no transactions to track.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.inkRed.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProcessingPage extends StatelessWidget {
  final String phase;
  final int totalFinancial;
  final int processed;
  final int matched;
  final int saved;
  final int banksFound;
  final bool scanComplete;

  const _ProcessingPage({
    required this.phase,
    required this.totalFinancial,
    required this.processed,
    required this.matched,
    required this.saved,
    required this.banksFound,
    required this.scanComplete,
  });

  String get _statusText {
    if (phase == 'reading') return 'Reading your messages...';
    if (phase == 'filtering') return 'Found $totalFinancial financial SMS';
    if (phase == 'parsing') {
      return 'Scanning... $processed / $totalFinancial';
    }
    if (phase == 'saving') return 'Saving $saved transactions...';
    return 'Processing...';
  }

  String get _detailText {
    if (phase == 'parsing' && matched > 0) {
      return '$matched transactions matched so far';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      pageIndex: -1,
      showNextButton: false,
      showDots: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!scanComplete) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.inkDark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Opening Your Ledger...',
              style: GoogleFonts.lora(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.inkFaded,
              ),
            ),
            if (_detailText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _detailText,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.inkFaded.withValues(alpha: 0.7),
                ),
              ),
            ],
          ] else ...[
            Icon(
              Icons.check_circle_outline,
              size: 52,
              color: AppTheme.inkDark.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'All Set',
              style: GoogleFonts.lora(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              saved > 0
                  ? 'Tracked $saved transactions\nfrom $banksFound bank${banksFound == 1 ? '' : 's'}'
                  : 'No transactions found yet.\nNew SMS will be tracked automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.inkFaded,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageLayout extends StatelessWidget {
  final int pageIndex;
  final VoidCallback? onNext;
  final bool showNextButton;
  final bool showDots;
  final Widget child;

  const _PageLayout({
    required this.pageIndex,
    this.onNext,
    this.showNextButton = true,
    this.showDots = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppTheme.parchmentLight,
      child: CustomPaint(
        painter: _OnboardingParchmentPainter(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 32, bottomPadding + 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                child,
                const Spacer(flex: 2),
                if (showDots) _buildDots(),
                if (showDots) const SizedBox(height: 28),
                if (showNextButton && onNext != null)
                  GestureDetector(
                    onTap: onNext,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Turn the page  \u2192',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.inkDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == pageIndex;
        return Container(
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.inkDark
                : AppTheme.inkDark.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}

class _OnboardingParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.ruled.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (double y = 28; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = AppTheme.inkRed.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(40, 0), Offset(40, size.height), marginPaint);

    final grainPaint = Paint()..color = AppTheme.ruled.withValues(alpha: 0.12);
    final rng = math.Random(77);
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 0.8 + 0.2, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
