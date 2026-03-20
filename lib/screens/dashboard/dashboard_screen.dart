import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/widgets/category_picker.dart';
import 'package:autotally_flutter/screens/dashboard/category_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late List<MockTransaction> _triageItems;
  int _currentTriageIndex = 0;
  int? _stampedCategoryId;
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;
  late AnimationController _dismissController;
  late Animation<Offset> _dismissSlide;
  late Animation<double> _dismissRotation;

  static const _shadowMedium = BoxShadow(
    color: Color(0x1A2C2416),
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  TextStyle _mono({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  void initState() {
    super.initState();
    _triageItems = PlaceholderData.triageTransactions();

    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stampScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.9), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _stampController,
      curve: Curves.easeOutCubic,
    ));
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.0, 0.3),
      ),
    );

    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _dismissSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, -0.1),
    ).animate(CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeInBack,
    ));
    _dismissRotation = Tween<double>(
      begin: 0.0,
      end: -0.08,
    ).animate(CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeInBack,
    ));
  }

  @override
  void dispose() {
    _stampController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _onCategorize(MockTransaction tx) async {
    final picked = await showCategoryPicker(context, selectedId: tx.categoryId);
    if (picked != null && mounted) {
      setState(() => _stampedCategoryId = picked.id);
      _stampController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _dismissController.forward().then((_) {
              if (mounted) {
                setState(() {
                  _stampedCategoryId = null;
                  _stampController.reset();
                  _dismissController.reset();
                  _currentTriageIndex++;
                });
              }
            });
          }
        });
      });
    }
  }

  void _onSkip() {
    _dismissController.forward().then((_) {
      if (mounted) {
        setState(() {
          _dismissController.reset();
          _currentTriageIndex++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTriageItems = _currentTriageIndex < _triageItems.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _buildTodaySnapshot(theme),
              ),
              const SizedBox(height: 32),
              if (hasTriageItems) ...[
                _buildTriageSection(theme),
              ],
              const SizedBox(height: 32),
              _buildBudgetProgress(theme),
              const SizedBox(height: 32),
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

  Widget _buildTriageSection(ThemeData theme) {
    final remaining = _triageItems.length - _currentTriageIndex;
    final tx = _triageItems[_currentTriageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Needs Your Attention',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.inkRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$remaining',
                  style: _mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (remaining > 1)
                Positioned(
                  left: 28,
                  right: 28,
                  top: 8,
                  bottom: -4,
                  child: Transform.rotate(
                    angle: 0.015,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.parchment.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.ruled, width: 0.5),
                      ),
                    ),
                  ),
                ),
              if (remaining > 2)
                Positioned(
                  left: 32,
                  right: 32,
                  top: 14,
                  bottom: -8,
                  child: Transform.rotate(
                    angle: -0.02,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.parchment.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.ruled, width: 0.5),
                      ),
                    ),
                  ),
                ),
              AnimatedBuilder(
                animation: _dismissController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _dismissSlide.value.dx * MediaQuery.of(context).size.width,
                      _dismissSlide.value.dy * 100,
                    ),
                    child: Transform.rotate(
                      angle: _dismissRotation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildTriageCard(theme, tx),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriageCard(ThemeData theme, MockTransaction tx) {
    final ext = context.appColors;
    final isDebit = tx.direction == 'debit';
    final stampCategory =
        _stampedCategoryId != null ? PlaceholderData.categoryById(_stampedCategoryId) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.ruled, width: 0.5),
        boxShadow: const [_shadowMedium],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _LedgerPainter(
          lineColor: AppTheme.ruled.withValues(alpha: 0.3),
          marginColor: AppTheme.inkRed.withValues(alpha: 0.18),
          spacing: 28,
          marginX: 12,
        ),
        foregroundPainter: _PaperGrainPainter(
          color: AppTheme.inkDark.withValues(alpha: 0.025),
          density: 80,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.merchantName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isDebit ? '-' : '+'} ${formatRupees(tx.amount)}',
                        style: _mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDebit ? ext.debit : ext.credit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(tx.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.parchmentLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.ruled.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tx.rawSms,
                      style: _mono(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ).copyWith(height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onCategorize(tx),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.inkDark.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.inkDark.withValues(alpha: 0.15),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Categorize',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _onSkip,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.ruled,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (stampCategory != null)
              AnimatedBuilder(
                animation: _stampController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Opacity(
                      opacity: _stampOpacity.value,
                      child: Transform.scale(
                        scale: _stampScale.value,
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: stampCategory.color,
                                  width: 3,
                                ),
                              ),
                              child: Text(
                                stampCategory.name.toUpperCase(),
                                style: _mono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: stampCategory.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySnapshot(ThemeData theme) {
    final ext = context.appColors;
    final todaySpent = PlaceholderData.totalSpentToday();
    final todayCount = PlaceholderData.transactionCountToday();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: ext.surfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.ruled, width: 0.5),
        boxShadow: const [_shadowMedium],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _LedgerRuledOnlyPainter(
          lineColor: AppTheme.ruled.withValues(alpha: 0.4),
          spacing: 28,
        ),
        foregroundPainter: _PaperGrainPainter(
          color: AppTheme.inkDark.withValues(alpha: 0.025),
          density: 80,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Text(
                '19 March 2026',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Today\'s Spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupees(todaySpent),
                style: _mono(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$todayCount transaction${todayCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetProgress(ThemeData theme) {
    final ext = context.appColors;
    final now = DateTime(2026, 3, 19);
    final totalBudget = PlaceholderData.monthlyBudget;
    final spent = PlaceholderData.totalSpentForMonth(now.year, now.month);
    final remaining = totalBudget - spent;
    final daysLeft = PlaceholderData.daysInMonth(now.year, now.month) - now.day + 1;
    final progress = (spent / totalBudget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Monthly Budget',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$daysLeft days left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _BudgetLedgerPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              inkColor: AppTheme.inkDark.withValues(alpha: 0.06),
              progress: progress,
              spacing: 24,
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 60,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BUDGET',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        formatRupees(totalBudget),
                        style: _mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SPENT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        formatRupees(spent),
                        style: _mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ext.debit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Container(height: 0.5, color: AppTheme.ruled),
                      const SizedBox(height: 2),
                      Container(height: 0.5, color: AppTheme.ruled),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REMAINING',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            remaining >= 0
                                ? formatRupees(remaining)
                                : '- ${formatRupees(remaining.abs())}',
                            style: _mono(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: remaining >= 0
                                  ? ext.credit
                                  : ext.debit,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(height: 1, width: 120, color: AppTheme.inkDark),
                          const SizedBox(height: 2),
                          Container(height: 1, width: 120, color: AppTheme.inkDark),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories(ThemeData theme) {
    final now = DateTime(2026, 3, 19);
    final allData = PlaceholderData.spendByCategoryForMonth(now.year, now.month);

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
            separatorBuilder: (_, _) => const SizedBox(width: 16),
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
                          initialMonth: DateTime(2026, 3),
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
                              color: AppTheme.inkFaded.withValues(alpha: 0.06),
                              border: Border.all(
                                color: AppTheme.inkDark.withValues(alpha: 0.25),
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
                                    color: AppTheme.inkDark.withValues(alpha: 0.12),
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]}, $hour:$min $ampm';
  }
}

class _LedgerRuledOnlyPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;

  _LedgerRuledOnlyPainter({required this.lineColor, this.spacing = 28});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LedgerRuledOnlyPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor || spacing != oldDelegate.spacing;
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

class _BudgetLedgerPainter extends CustomPainter {
  final Color lineColor;
  final Color inkColor;
  final double progress;
  final double spacing;

  _BudgetLedgerPainter({
    required this.lineColor,
    required this.inkColor,
    required this.progress,
    this.spacing = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final inkPaint = Paint()..color = inkColor;
    final filledHeight = size.height * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, filledHeight),
      inkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetLedgerPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      inkColor != oldDelegate.inkColor ||
      progress != oldDelegate.progress ||
      spacing != oldDelegate.spacing;
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
