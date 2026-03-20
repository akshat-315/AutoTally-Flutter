import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _selectedMonth = DateTime(2026, 3);

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

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildMonthSelector(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildMonthlySummary(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _buildSpendingPulse(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _buildCategoryBreakdown(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _buildMonthlyTrend(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _buildTopMerchants(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _buildDayOfWeekPattern(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        'Analytics',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevMonth,
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.parchment,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.ruled, width: 0.5),
              ),
            ),
          ),
          Text(
            PlaceholderData.monthLabel(_selectedMonth),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.parchment,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.ruled, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(ThemeData theme) {
    final ext = context.appColors;
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final spent = PlaceholderData.totalSpentForMonth(year, month);
    final income = PlaceholderData.totalReceivedForMonth(year, month);
    final net = income - spent;
    final txCount = PlaceholderData.transactionCountForMonth(year, month);
    final debitCount = PlaceholderData.debitCountForMonth(year, month);
    final creditCount = PlaceholderData.creditCountForMonth(year, month);

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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INCOME',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '+ ${formatRupees(income)}',
                    style: _mono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ext.credit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$creditCount transaction${creditCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
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
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '- ${formatRupees(spent)}',
                    style: _mono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ext.debit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$debitCount transaction${debitCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
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
                    'NET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        net >= 0
                            ? '+ ${formatRupees(net)}'
                            : '- ${formatRupees(net.abs())}',
                        style: _mono(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: net >= 0 ? ext.credit : ext.debit,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(height: 1, width: 130, color: AppTheme.inkDark),
                      const SizedBox(height: 2),
                      Container(height: 1, width: 130, color: AppTheme.inkDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$txCount total transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingPulse(ThemeData theme) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final cumulative = (year == 2026 && month == 3)
        ? PlaceholderData.cumulativeDailySpend(year, month)
        : PlaceholderData.syntheticCumulativeDailySpend(year, month);
    final days = PlaceholderData.daysInMonth(year, month);
    final budget = PlaceholderData.monthlyBudget;
    final currentDay = (year == 2026 && month == 3) ? 19 : days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Pulse',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cumulative daily spend vs budget pace',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _SpendingPulsePainter(
              cumulative: cumulative,
              totalDays: days,
              currentDay: currentDay,
              budget: budget,
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              inkColor: AppTheme.inkDark,
              budgetLineColor: AppTheme.inkBlue.withValues(alpha: 0.4),
              fillColor: AppTheme.inkDark.withValues(alpha: 0.06),
              overBudgetColor: AppTheme.inkRed.withValues(alpha: 0.15),
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 60,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(width: 16, height: 2, color: AppTheme.inkDark),
              const SizedBox(width: 6),
              Text(
                'Spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.inkBlue.withValues(alpha: 0.4),
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Budget pace',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final data = PlaceholderData.spendByCategoryForMonth(year, month);

    if (data.isEmpty) {
      return _buildEmptySection(theme, 'Category Breakdown');
    }

    final maxAmount = data.first.total;

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
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _LedgerRuledOnlyPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.25),
              spacing: 48,
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 60,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (int i = 0; i < data.length; i++) ...[
                    _buildCategoryRow(theme, data[i], maxAmount, i),
                    if (i < data.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 0.5,
                          color: AppTheme.ruled.withValues(alpha: 0.3),
                        ),
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

  Widget _buildCategoryRow(
    ThemeData theme,
    ({MockCategory category, int total}) item,
    int maxAmount,
    int index,
  ) {
    final proportion = maxAmount > 0 ? item.total / maxAmount : 0.0;
    final totalSpent = PlaceholderData.totalSpentForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final percentage = totalSpent > 0
        ? (item.total / totalSpent * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              item.category.icon,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          formatRupees(item.total),
                          style: _mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$percentage%',
                          style: _mono(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: CustomPaint(
                      painter: _InkBarPainter(
                        progress: proportion,
                        inkColor: AppTheme.inkDark.withValues(alpha: 0.4),
                        trackColor: AppTheme.ruled.withValues(alpha: 0.3),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend(ThemeData theme) {
    final trend = PlaceholderData.monthlyTrend();
    final maxSpent = trend.map((t) => t.spent).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Last 6 months spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _MonthlyTrendPainter(
              data: trend,
              maxValue: maxSpent,
              selectedMonth: _selectedMonth,
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              barColor: AppTheme.inkDark.withValues(alpha: 0.15),
              selectedBarColor: AppTheme.inkDark.withValues(alpha: 0.5),
              textColor: AppTheme.inkFaded,
              valueColor: AppTheme.inkDark,
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 50,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMerchants(ThemeData theme) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final data = PlaceholderData.topMerchantsForMonth(year, month, limit: 5);

    if (data.isEmpty) {
      return _buildEmptySection(theme, 'Top Merchants');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Merchants',
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
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _MerchantLedgerPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              marginColor: AppTheme.inkRed.withValues(alpha: 0.15),
              spacing: 52,
              marginX: 44,
            ),
            foregroundPainter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 60,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (int i = 0; i < data.length; i++)
                    _buildMerchantRow(theme, data[i], i + 1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantRow(
    ThemeData theme,
    ({MockMerchant merchant, int total, int count}) item,
    int rank,
  ) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$rank',
                style: _mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkFaded.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.merchant.display,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.count} transaction${item.count == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupees(item.total),
                    style: _mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOfWeekPattern(ThemeData theme) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final totals = PlaceholderData.dayOfWeekTotals(year, month);
    final maxVal = totals.values.isEmpty ? 1 : totals.values.reduce(math.max);

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending by Day',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Which days cost the most',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _PaperGrainPainter(
              color: AppTheme.inkDark.withValues(alpha: 0.02),
              density: 40,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final dow = i + 1;
                final value = totals[dow] ?? 0;
                final proportion = maxVal > 0 ? value / maxVal : 0.0;
                final isWeekend = dow >= 6;

                return Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (value > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  formatRupees(value),
                                  style: _mono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Container(
                              width: 24,
                              height: math.max(4, proportion * 80),
                              decoration: BoxDecoration(
                                color: isWeekend
                                    ? AppTheme.inkRed.withValues(alpha: 0.3)
                                    : AppTheme.inkDark.withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabels[i],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: isWeekend ? FontWeight.w700 : FontWeight.w500,
                          color: isWeekend
                              ? AppTheme.inkRed
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
          ),
          child: Center(
            child: Text(
              'No data for this month',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
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

class _SpendingPulsePainter extends CustomPainter {
  final Map<int, int> cumulative;
  final int totalDays;
  final int currentDay;
  final int budget;
  final Color lineColor;
  final Color inkColor;
  final Color budgetLineColor;
  final Color fillColor;
  final Color overBudgetColor;

  _SpendingPulsePainter({
    required this.cumulative,
    required this.totalDays,
    required this.currentDay,
    required this.budget,
    required this.lineColor,
    required this.inkColor,
    required this.budgetLineColor,
    required this.fillColor,
    required this.overBudgetColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(40, 20, 16, 30);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final maxCumulative = cumulative.values.isEmpty
        ? budget
        : cumulative.values.reduce(math.max);
    final yMax = math.max(budget, maxCumulative) * 1.1;

    final ruledPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = padding.top; y < size.height - padding.bottom; y += 28) {
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        ruledPaint,
      );
    }

    final budgetPaint = Paint()
      ..color = budgetLineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final budgetY = padding.top + chartHeight * (1 - budget / yMax);
    final dashWidth = 6.0;
    final dashGap = 4.0;
    double dx = padding.left;
    while (dx < size.width - padding.right) {
      canvas.drawLine(
        Offset(dx, budgetY),
        Offset(math.min(dx + dashWidth, size.width - padding.right), budgetY),
        budgetPaint,
      );
      dx += dashWidth + dashGap;
    }

    if (cumulative.isEmpty) return;

    final path = Path();
    final fillPath = Path();
    bool started = false;

    for (int d = 1; d <= currentDay; d++) {
      final val = cumulative[d] ?? (d > 1 ? cumulative[d - 1] ?? 0 : 0);
      final x = padding.left + (d - 1) / (totalDays - 1) * chartWidth;
      final y = padding.top + chartHeight * (1 - val / yMax);

      if (!started) {
        path.moveTo(x, y);
        fillPath.moveTo(x, padding.top + chartHeight);
        fillPath.lineTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final lastX = padding.left + (currentDay - 1) / (totalDays - 1) * chartWidth;
    fillPath.lineTo(lastX, padding.top + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = inkColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (int d = 1; d <= currentDay; d++) {
      final val = cumulative[d] ?? 0;
      if (val == 0 && d > 1) continue;
      final x = padding.left + (d - 1) / (totalDays - 1) * chartWidth;
      final y = padding.top + chartHeight * (1 - val / yMax);

      canvas.drawCircle(
        Offset(x, y),
        d == currentDay ? 4 : 2,
        Paint()..color = inkColor,
      );

      if (d == currentDay) {
        canvas.drawCircle(
          Offset(x, y),
          6,
          Paint()
            ..color = inkColor.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '1',
      style: TextStyle(fontSize: 9, color: inkColor.withValues(alpha: 0.5)),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding.left, size.height - padding.bottom + 8));

    final midDay = totalDays ~/ 2;
    textPainter.text = TextSpan(
      text: '$midDay',
      style: TextStyle(fontSize: 9, color: inkColor.withValues(alpha: 0.5)),
    );
    textPainter.layout();
    final midX = padding.left + (midDay - 1) / (totalDays - 1) * chartWidth;
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, size.height - padding.bottom + 8));

    textPainter.text = TextSpan(
      text: '$totalDays',
      style: TextStyle(fontSize: 9, color: inkColor.withValues(alpha: 0.5)),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - padding.right - textPainter.width, size.height - padding.bottom + 8),
    );

    final yLabels = [0, (yMax ~/ 2), yMax.toInt()];
    for (final val in yLabels) {
      final label = '₹${formatIndianNumber(val ~/ 100)}';
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(fontSize: 8, color: inkColor.withValues(alpha: 0.4)),
      );
      textPainter.layout();
      final ly = padding.top + chartHeight * (1 - val / yMax);
      textPainter.paint(canvas, Offset(2, ly - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingPulsePainter oldDelegate) => true;
}

class _MonthlyTrendPainter extends CustomPainter {
  final List<({DateTime month, int spent, int income})> data;
  final int maxValue;
  final DateTime selectedMonth;
  final Color lineColor;
  final Color barColor;
  final Color selectedBarColor;
  final Color textColor;
  final Color valueColor;

  static const _shortMonths = ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];

  _MonthlyTrendPainter({
    required this.data,
    required this.maxValue,
    required this.selectedMonth,
    required this.lineColor,
    required this.barColor,
    required this.selectedBarColor,
    required this.textColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = const EdgeInsets.fromLTRB(12, 16, 12, 32);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final ruledPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double y = padding.top; y < size.height - padding.bottom; y += 28) {
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        ruledPaint,
      );
    }

    final barCount = data.length;
    final barGroupWidth = chartWidth / barCount;
    final barWidth = barGroupWidth * 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < barCount; i++) {
      final item = data[i];
      final isSelected = item.month.year == selectedMonth.year &&
          item.month.month == selectedMonth.month;
      final proportion = maxValue > 0 ? item.spent / maxValue : 0.0;
      final barHeight = proportion * chartHeight;

      final x = padding.left + i * barGroupWidth + (barGroupWidth - barWidth) / 2;
      final y = padding.top + chartHeight - barHeight;

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      canvas.drawRRect(
        barRect,
        Paint()..color = isSelected ? selectedBarColor : barColor,
      );

      if (isSelected) {
        canvas.drawRRect(
          barRect,
          Paint()
            ..color = valueColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      final label = i < _shortMonths.length ? _shortMonths[i] : '${item.month.month}';
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? valueColor : textColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - textPainter.width / 2,
          size.height - padding.bottom + 8,
        ),
      );

      textPainter.text = TextSpan(
        text: '₹${formatIndianNumber(item.spent ~/ 100)}',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isSelected ? valueColor : textColor.withValues(alpha: 0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) => true;
}

class _InkBarPainter extends CustomPainter {
  final double progress;
  final Color inkColor;
  final Color trackColor;

  _InkBarPainter({
    required this.progress,
    required this.inkColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(3),
      ),
      Paint()..color = trackColor,
    );

    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * progress, size.height),
          const Radius.circular(3),
        ),
        Paint()..color = inkColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkBarPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      inkColor != oldDelegate.inkColor ||
      trackColor != oldDelegate.trackColor;
}

class _MerchantLedgerPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double spacing;
  final double marginX;

  _MerchantLedgerPainter({
    required this.lineColor,
    required this.marginColor,
    this.spacing = 52,
    this.marginX = 44,
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
  bool shouldRepaint(covariant _MerchantLedgerPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      marginColor != oldDelegate.marginColor;
}
