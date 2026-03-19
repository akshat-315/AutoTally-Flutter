import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/month_picker.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/screens/dashboard/category_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _currentMonth = DateTime(2026, 3);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  TextStyle _mono({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static const _shadowMedium = BoxShadow(
    color: Color(0x1A2C2416),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildHeroCard(theme),
              const SizedBox(height: 40),
              _buildLedgerSection(theme),
              const SizedBox(height: 40),
              _buildTopCategories(theme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Akshat',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const ReviewBell(),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final ext = context.appColors;
    final spent = PlaceholderData.totalSpentForMonth(
        _currentMonth.year, _currentMonth.month);
    final received = PlaceholderData.totalReceivedForMonth(
        _currentMonth.year, _currentMonth.month);
    final expenses = PlaceholderData.totalSpentForMonth(
        _currentMonth.year, _currentMonth.month);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: ext.surfaceGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.ruled, width: 0.5),
                boxShadow: const [_shadowMedium],
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: _LedgerPainter(
                  lineColor: AppTheme.ruled.withValues(alpha: 0.5),
                  marginColor: AppTheme.inkRed.withValues(alpha: 0.2),
                  spacing: 28,
                  marginX: 32,
                ),
                foregroundPainter: _PaperGrainPainter(
                  color: AppTheme.inkDark.withValues(alpha: 0.03),
                  density: 80,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 52),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await showMonthPicker(
                            context,
                            selected: _currentMonth,
                          );
                          if (picked != null) {
                            setState(() => _currentMonth = picked);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              PlaceholderData.monthLabel(_currentMonth),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Spent',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatRupees(spent),
                        style: _mono(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -22,
              left: 40,
              right: 40,
              child: Row(
                children: [
                  _buildStatChip(
                    theme,
                    'Income',
                    formatRupees(received),
                    AppTheme.inkBlue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    theme,
                    'Expenses',
                    formatRupees(expenses),
                    AppTheme.inkRed,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildStatChip(
      ThemeData theme, String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.parchmentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x0F2C2416),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: _mono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerSection(ThemeData theme) {
    final ext = context.appColors;
    final txns = PlaceholderData.transactionsForMonth(
        _currentMonth.year, _currentMonth.month);
    final recent = txns.take(5).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _LedgerPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.4),
              marginColor: AppTheme.inkRed.withValues(alpha: 0.18),
              spacing: 52,
              marginX: 62,
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 60,
            ),
            child: Column(
              children: [
                for (int i = 0; i < recent.length; i++)
                  _buildLedgerRow(theme, ext, recent[i], i == recent.length - 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerRow(
      ThemeData theme, AppThemeExtension ext, MockTransaction tx, bool isLast) {
    final isDebit = tx.direction == 'debit';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            SlidePageRoute(
              child: TransactionDetailScreen(transaction: tx),
            ),
          );
        },
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Center(
                  child: Text(
                    PlaceholderData.shortDate(tx.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    tx.merchantName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 1),
                        painter: _DottedLinePainter(
                          color: AppTheme.ruled,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${isDebit ? '-' : '+'} ${formatRupees(tx.amount)}',
                  style: _mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDebit ? ext.debit : ext.credit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategories(ThemeData theme) {
    final allData = PlaceholderData.spendByCategoryForMonth(
        _currentMonth.year, _currentMonth.month);

    if (allData.isEmpty) return const SizedBox.shrink();

    final data = allData.length >= 5
        ? allData.take(5).toList()
        : allData.take(3).toList();

    final stampRotations = List.generate(
      data.length,
      (i) => (math.Random(i * 7).nextDouble() - 0.5) * 0.12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where It Went',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 0.5, color: AppTheme.ruled),
              const SizedBox(height: 2),
              Container(height: 0.5, color: AppTheme.ruled),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = data[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        child: CategoryDetailScreen(
                          category: item.category,
                          initialMonth: _currentMonth,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Transform.rotate(
                          angle: stampRotations[index],
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.inkFaded
                                  .withValues(alpha: 0.06),
                              border: Border.all(
                                color: AppTheme.inkDark
                                    .withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.inkDark
                                        .withValues(alpha: 0.12),
                                    width: 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    item.category.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.category.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupees(item.total),
                          style: _mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LedgerPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double spacing;
  final double marginX;

  _LedgerPainter({
    required this.lineColor,
    required this.marginColor,
    this.spacing = 28,
    this.marginX = 32,
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
      Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LedgerPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      spacing != oldDelegate.spacing ||
      marginColor != oldDelegate.marginColor ||
      marginX != oldDelegate.marginX;
}

class _PaperGrainPainter extends CustomPainter {
  final Color color;
  final int density;

  _PaperGrainPainter({required this.color, this.density = 80});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rng = math.Random(42);

    for (int i = 0; i < density; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) =>
      color != oldDelegate.color || density != oldDelegate.density;
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const dashWidth = 1.5;
    const gap = 3.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawCircle(Offset(x, y), dashWidth / 2, paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
