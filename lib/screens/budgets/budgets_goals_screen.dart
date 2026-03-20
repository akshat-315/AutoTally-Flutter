import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/screens/budgets/goal_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class BudgetsGoalsScreen extends StatelessWidget {
  const BudgetsGoalsScreen({super.key});

  TextStyle _mono({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets & Goals')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildOverallBudget(context, theme),
            const SizedBox(height: 32),
            _buildCategoryBudgets(context, theme),
            const SizedBox(height: 36),
            _buildSavingsGoals(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallBudget(BuildContext context, ThemeData theme) {
    final ext = context.appColors;
    final now = DateTime(2026, 3, 19);
    final totalBudget = PlaceholderData.monthlyBudget;
    final spent = PlaceholderData.totalSpentForMonth(now.year, now.month);
    final remaining = totalBudget - spent;
    final daysLeft = PlaceholderData.daysInMonth(now.year, now.month) - now.day + 1;
    final progress = (spent / totalBudget).clamp(0.0, 1.0);
    final dailyBudgetLeft = remaining > 0 ? remaining ~/ daysLeft : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'March 2026',
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2C2416),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
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
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
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
                              color: remaining >= 0 ? ext.credit : ext.debit,
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
                  if (dailyBudgetLeft > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '~ ${formatRupees(dailyBudgetLeft)} / day',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgets(BuildContext context, ThemeData theme) {
    final ext = context.appColors;
    final now = DateTime(2026, 3, 19);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By Category',
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
        const SizedBox(height: 16),
        ...PlaceholderData.categoryBudgets.map((cb) {
          final category = PlaceholderData.categoryById(cb.categoryId)!;
          final spent = PlaceholderData.spentForCategory(
              cb.categoryId, now.year, now.month);
          final remaining = cb.budgetAmount - spent;
          final progress = (spent / cb.budgetAmount).clamp(0.0, 1.0);
          final isOver = remaining < 0;

          return _buildCategoryBudgetRow(
            context, theme, ext, category, cb.budgetAmount, spent,
            remaining, progress, isOver,
          );
        }),
      ],
    );
  }

  Widget _buildCategoryBudgetRow(
    BuildContext context,
    ThemeData theme,
    AppThemeExtension ext,
    MockCategory category,
    int budget,
    int spent,
    int remaining,
    double progress,
    bool isOver,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOver
              ? AppTheme.inkRed.withValues(alpha: 0.3)
              : AppTheme.ruled,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatRupees(spent)} / ${formatRupees(budget)}',
                    style: _mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOver
                        ? 'Over by ${formatRupees(remaining.abs())}'
                        : '${formatRupees(remaining)} left',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isOver ? ext.debit : ext.credit,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: CustomPaint(
                size: const Size(double.infinity, 4),
                painter: _InkProgressPainter(
                  progress: progress,
                  inkColor: isOver
                      ? AppTheme.inkRed.withValues(alpha: 0.6)
                      : AppTheme.inkDark.withValues(alpha: 0.4),
                  bgColor: AppTheme.ruled.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoals(BuildContext context, ThemeData theme) {
    final goals = PlaceholderData.savingsGoals;
    final now = DateTime(2026, 3, 19);
    final totalIncome = PlaceholderData.totalReceivedForMonth(now.year, now.month);
    final totalSpent = PlaceholderData.totalSpentForMonth(now.year, now.month);
    final surplus = totalIncome - totalSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings Goals',
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
        if (surplus > 0) ...[
          const SizedBox(height: 12),
          _buildSurplusNudge(context, theme, surplus),
        ],
        const SizedBox(height: 16),
        ...goals.map((goal) => _buildGoalRow(context, theme, goal)),
      ],
    );
  }

  Widget _buildSurplusNudge(BuildContext context, ThemeData theme, int surplus) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.inkBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.inkBlue.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppTheme.inkBlue.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: formatRupees(surplus),
                    style: _mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' unallocated this month'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, ThemeData theme, MockSavingsGoal goal) {
    final deadlineText = goal.deadline != null
        ? _formatDeadline(goal.deadline!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            SlidePageRoute(child: GoalDetailScreen(goal: goal)),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.inkFaded.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppTheme.inkDark.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(goal.icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 16,
                      child: CustomPaint(
                        size: const Size(double.infinity, 16),
                        painter: _InkFillingTextPainter(
                          fullText: formatRupees(goal.targetAmount),
                          progress: goal.progress,
                          filledColor: AppTheme.inkDark,
                          unfilledColor: AppTheme.ruled,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (deadlineText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        deadlineText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime(2026, 3, 19);
    final daysLeft = deadline.difference(now).inDays;
    if (daysLeft < 0) return 'Overdue';
    if (daysLeft == 0) return 'Due today';
    return 'by ${deadline.day} ${months[deadline.month - 1]} ${deadline.year} · ${daysLeft}d left';
  }
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

class _InkProgressPainter extends CustomPainter {
  final double progress;
  final Color inkColor;
  final Color bgColor;

  _InkProgressPainter({
    required this.progress,
    required this.inkColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      bgPaint,
    );

    final inkPaint = Paint()..color = inkColor;
    final filledWidth = size.width * progress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, filledWidth, size.height),
        const Radius.circular(2),
      ),
      inkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _InkProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      inkColor != oldDelegate.inkColor ||
      bgColor != oldDelegate.bgColor;
}

class _InkFillingTextPainter extends CustomPainter {
  final String fullText;
  final double progress;
  final Color filledColor;
  final Color unfilledColor;
  final double fontSize;

  _InkFillingTextPainter({
    required this.fullText,
    required this.progress,
    required this.filledColor,
    required this.unfilledColor,
    this.fontSize = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final monoFont = GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
    );

    final unfilledPainter = TextPainter(
      text: TextSpan(
        text: fullText,
        style: monoFont.copyWith(color: unfilledColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    unfilledPainter.paint(canvas, Offset(0, (size.height - unfilledPainter.height) / 2));

    final filledWidth = unfilledPainter.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, filledWidth, size.height));

    final filledPainter = TextPainter(
      text: TextSpan(
        text: fullText,
        style: monoFont.copyWith(color: filledColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    filledPainter.paint(canvas, Offset(0, (size.height - filledPainter.height) / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InkFillingTextPainter oldDelegate) =>
      fullText != oldDelegate.fullText ||
      progress != oldDelegate.progress ||
      filledColor != oldDelegate.filledColor ||
      unfilledColor != oldDelegate.unfilledColor;
}
