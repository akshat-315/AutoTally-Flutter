import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';

class GoalDetailScreen extends StatelessWidget {
  final MockSavingsGoal goal;

  const GoalDetailScreen({super.key, required this.goal});

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
    final ext = context.appColors;
    final remaining = goal.targetAmount - goal.savedAmount;

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProgressCard(context, theme, ext, remaining),
            const SizedBox(height: 24),
            _buildAllocationLedger(context, theme, ext),
            const SizedBox(height: 24),
            _buildAddButton(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      BuildContext context, ThemeData theme, AppThemeExtension ext, int remaining) {
    final deadlineText = goal.deadline != null ? _formatDeadline(goal.deadline!) : null;

    return Container(
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
        painter: _LedgerRuledPainter(
          lineColor: AppTheme.ruled.withValues(alpha: 0.3),
          spacing: 28,
        ),
        foregroundPainter: _PaperGrainPainter(
          color: AppTheme.inkDark.withValues(alpha: 0.025),
          density: 80,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                'TARGET',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatRupees(goal.targetAmount),
                style: _mono(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 20,
                child: CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: _InkFillingTextPainter(
                    fullText: formatRupees(goal.targetAmount),
                    progress: goal.progress,
                    filledColor: AppTheme.inkDark,
                    unfilledColor: AppTheme.ruled,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupees(goal.savedAmount),
                        style: _mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ext.credit,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'REMAINING',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRupees(remaining.abs()),
                            style: _mono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(height: 1, width: 80, color: AppTheme.inkDark),
                          const SizedBox(height: 2),
                          Container(height: 1, width: 80, color: AppTheme.inkDark),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (deadlineText != null) ...[
                const SizedBox(height: 16),
                Text(
                  deadlineText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationLedger(
      BuildContext context, ThemeData theme, AppThemeExtension ext) {
    if (goal.allocations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allocation Register',
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
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _AllocationLedgerPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              marginColor: AppTheme.inkRed.withValues(alpha: 0.18),
              spacing: 48,
              marginX: 80,
            ),
            child: Column(
              children: [
                for (int i = 0; i < goal.allocations.length; i++)
                  _buildAllocationRow(
                    theme, ext, goal.allocations[i],
                    i == goal.allocations.length - 1,
                  ),
                _buildRunningTotal(theme, ext),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationRow(
      ThemeData theme, AppThemeExtension ext, MockGoalAllocation allocation, bool isLast) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                _formatShortDate(allocation.date),
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
                allocation.note ?? 'Allocation',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '+ ${formatRupees(allocation.amount)}',
              style: _mono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ext.credit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningTotal(ThemeData theme, AppThemeExtension ext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.ruled, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total  ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupees(goal.savedAmount),
                style: _mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(height: 1, width: 90, color: AppTheme.inkDark),
              const SizedBox(height: 2),
              Container(height: 1, width: 90, color: AppTheme.inkDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inkDark.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.inkDark.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add Money',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
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
    return 'Due by ${deadline.day} ${months[deadline.month - 1]} ${deadline.year} · $daysLeft days left';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _LedgerRuledPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;

  _LedgerRuledPainter({required this.lineColor, this.spacing = 28});

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
  bool shouldRepaint(covariant _LedgerRuledPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor || spacing != oldDelegate.spacing;
}

class _AllocationLedgerPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double spacing;
  final double marginX;

  _AllocationLedgerPainter({
    required this.lineColor,
    required this.marginColor,
    this.spacing = 48,
    this.marginX = 80,
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
  bool shouldRepaint(covariant _AllocationLedgerPainter oldDelegate) =>
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

    final xOffset = (size.width - unfilledPainter.width) / 2;
    final yOffset = (size.height - unfilledPainter.height) / 2;

    unfilledPainter.paint(canvas, Offset(xOffset, yOffset));

    final filledWidth = unfilledPainter.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(xOffset, 0, filledWidth, size.height));

    final filledPainter = TextPainter(
      text: TextSpan(
        text: fullText,
        style: monoFont.copyWith(color: filledColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    filledPainter.paint(canvas, Offset(xOffset, yOffset));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InkFillingTextPainter oldDelegate) =>
      fullText != oldDelegate.fullText ||
      progress != oldDelegate.progress ||
      filledColor != oldDelegate.filledColor ||
      unfilledColor != oldDelegate.unfilledColor;
}
