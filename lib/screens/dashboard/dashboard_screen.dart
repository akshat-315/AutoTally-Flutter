import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/main.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/screens/settings/settings_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';
import 'package:autotally_flutter/widgets/animated_entrance.dart';

enum DatePreset { today, thisWeek, thisMonth, thisYear, custom }

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  DatePreset _activePreset = DatePreset.thisMonth;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  int _spent = 0;
  int _received = 0;
  int _txCount = 0;
  int _debitCount = 0;
  int _creditCount = 0;
  List<MockTransaction> _recentTransactions = [];
  Map<int, int> _cumulative = {};
  int _cumulativeTotalDays = 0;
  List<({MockCategory category, int total})> _categoryData = [];
  List<({String name, int total, int count})> _topMerchants = [];
  Map<int, int> _dowTotals = {};
  List<({DateTime month, int spent, int income})> _trend = [];

  late AnimationController _dataAnimController;
  late Animation<double> _dataFadeAnim;

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
    _dataAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dataFadeAnim = CurvedAnimation(
      parent: _dataAnimController,
      curve: Curves.easeOut,
    );
    _applyPreset(DatePreset.thisMonth);
  }

  @override
  void dispose() {
    _dataAnimController.dispose();
    super.dispose();
  }

  void _applyPreset(DatePreset preset) {
    final now = DateTime.now();
    setState(() => _activePreset = preset);

    switch (preset) {
      case DatePreset.today:
        _rangeStart = DateTime(now.year, now.month, now.day);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisWeek:
        final weekday = now.weekday;
        _rangeStart = DateTime(now.year, now.month, now.day - weekday + 1);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisMonth:
        _rangeStart = DateTime(now.year, now.month, 1);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisYear:
        _rangeStart = DateTime(now.year, 1, 1);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.custom:
        return;
    }
    _loadData();
  }

  void _applyCustomRange(DateTime start, DateTime end) {
    setState(() {
      _activePreset = DatePreset.custom;
      _rangeStart = start;
      _rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    _dataAnimController.reverse();
    setState(() => _isLoading = true);

    final results = await Future.wait([
      queryService.rangeStats(_rangeStart, _rangeEnd),
      queryService.transactionsForRange(_rangeStart, _rangeEnd),
      queryService.cumulativeDailySpendForRange(_rangeStart, _rangeEnd),
      queryService.spendByCategoryForRange(_rangeStart, _rangeEnd),
      queryService.topMerchantsForRange(_rangeStart, _rangeEnd),
      queryService.dayOfWeekTotalsForRange(_rangeStart, _rangeEnd),
      queryService.trendForRange(_rangeStart, _rangeEnd),
    ]);

    if (!mounted) return;

    final stats =
        results[0]
            as ({
              int spent,
              int received,
              int txCount,
              int debitCount,
              int creditCount,
            });
    final allTxns = results[1] as List<MockTransaction>;

    setState(() {
      _spent = stats.spent;
      _received = stats.received;
      _txCount = stats.txCount;
      _debitCount = stats.debitCount;
      _creditCount = stats.creditCount;
      _recentTransactions = allTxns.take(5).toList();
      _cumulative = results[2] as Map<int, int>;
      _cumulativeTotalDays = _rangeEnd.difference(_rangeStart).inDays + 1;
      _categoryData = results[3] as List<({MockCategory category, int total})>;
      _topMerchants = results[4] as List<({String name, int total, int count})>;
      _dowTotals = results[5] as Map<int, int>;
      _trend = results[6] as List<({DateTime month, int spent, int income})>;
      _isLoading = false;
    });

    _dataAnimController.forward();
  }

  Future<void> _showCustomRangePicker() async {
    String initialStart = '';
    String initialEnd = '';
    if (_activePreset == DatePreset.custom) {
      initialStart =
          '${_rangeStart.day.toString().padLeft(2, '0')}/${_rangeStart.month.toString().padLeft(2, '0')}/${_rangeStart.year}';
      initialEnd =
          '${_rangeEnd.day.toString().padLeft(2, '0')}/${_rangeEnd.month.toString().padLeft(2, '0')}/${_rangeEnd.year}';
    }

    final result = await showModalBottomSheet<(DateTime, DateTime)?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.parchmentLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DateRangeInputSheet(
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );

    if (result != null) {
      _applyCustomRange(result.$1, result.$2);
    }
  }

  String _rangeDateLabel() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final s = _rangeStart;
    final e = _rangeEnd;
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return '${s.day} ${months[s.month - 1]} ${s.year}';
    }
    if (s.year == e.year) {
      return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]}';
    }
    return '${s.day} ${months[s.month - 1]} ${s.year} – ${e.day} ${months[e.month - 1]} ${e.year}';
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
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildDateFilterBar(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.inkDark,
                    strokeWidth: 2,
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _dataFadeAnim,
                  child: Column(
                    children: [
                      FadeSlideIn(
                        index: 0,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildSummaryCard(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 1,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildRecentTransactions(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 2,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildSpendingPulse(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 3,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildCategorySeals(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 4,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildReceiptBoard(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 5,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildTallyMarks(theme),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        index: 6,
                        slideOffset: const Offset(0, 0.05),
                        child: _buildTrendChart(theme),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ],
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                SlidePageRoute(child: const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(ThemeData theme) {
    final presets = [
      (DatePreset.today, 'Today'),
      (DatePreset.thisWeek, 'Week'),
      (DatePreset.thisMonth, 'Month'),
      (DatePreset.thisYear, 'Year'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              ...presets.map((p) {
                final isActive = _activePreset == p.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _applyPreset(p.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.inkDark
                              : AppTheme.parchment,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? AppTheme.inkDark : AppTheme.ruled,
                            width: isActive ? 1.5 : 0.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.inkDark.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            p.$2,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? AppTheme.parchmentLight
                                  : AppTheme.inkFaded,
                              fontSize: 12,
                              letterSpacing: isActive ? 0.5 : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _showCustomRangePicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _activePreset == DatePreset.custom
                        ? AppTheme.inkDark
                        : AppTheme.parchment,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _activePreset == DatePreset.custom
                          ? AppTheme.inkDark
                          : AppTheme.ruled,
                      width: _activePreset == DatePreset.custom ? 1.5 : 0.5,
                    ),
                  ),
                  child: Icon(
                    Icons.date_range_rounded,
                    size: 16,
                    color: _activePreset == DatePreset.custom
                        ? AppTheme.parchmentLight
                        : AppTheme.inkFaded,
                  ),
                ),
              ),
            ],
          ),
          if (_activePreset == DatePreset.custom) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCustomRangePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.parchment,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.ruled, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.inkFaded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _rangeDateLabel(),
                      style: _mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final ext = context.appColors;
    final net = _received - _spent;

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
        painter: _LedgerRuledPainter(
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'SPENT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CountUpText(
                          value: _spent,
                          formatter: formatRupees,
                          style: _mono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ext.debit,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_debitCount txns',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 60,
                    color: AppTheme.ruled.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'RECEIVED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CountUpText(
                          value: _received,
                          formatter: (v) => '+ ${formatRupees(v)}',
                          style: _mono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ext.credit,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_creditCount txns',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NET  ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  Column(
                    children: [
                      CountUpText(
                        value: net.abs(),
                        formatter: (v) => net >= 0
                            ? '+ ${formatRupees(v)}'
                            : '- ${formatRupees(v)}',
                        style: _mono(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: net >= 0 ? ext.credit : ext.debit,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(height: 1, width: 140, color: AppTheme.inkDark),
                      const SizedBox(height: 2),
                      Container(height: 1, width: 140, color: AppTheme.inkDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_txCount total transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onSwitchTab?.call(1),
                child: Text(
                  'See all',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
            painter: _TornEdgePainter(color: AppTheme.parchmentLight),
            child: _recentTransactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No transactions in this period',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      ..._recentTransactions.map(
                        (tx) => TransactionRow(
                          transaction: tx,
                          onTap: () {
                            Navigator.push(
                              context,
                              SlidePageRoute(
                                child: TransactionDetailScreen(transaction: tx),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingPulse(ThemeData theme) {
    final totalDays = _cumulativeTotalDays;
    final budget = PlaceholderData.monthlyBudget;
    final currentDay = _cumulative.keys.isEmpty
        ? 1
        : _cumulative.keys.reduce(math.max);

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
            painter: _GraphPaperPainter(
              lineColor: AppTheme.ruled.withValues(alpha: 0.2),
              majorSpacing: 28,
            ),
            foregroundPainter: _SpendingPulsePainter(
              cumulative: _cumulative,
              totalDays: totalDays,
              currentDay: currentDay,
              budget: budget,
              inkColor: AppTheme.inkDark,
              budgetLineColor: AppTheme.inkBlue.withValues(alpha: 0.4),
              fillColor: AppTheme.inkDark.withValues(alpha: 0.06),
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
                height: 0,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.inkBlue.withValues(alpha: 0.4),
                      width: 1,
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

  Widget _buildCategorySeals(ThemeData theme) {
    if (_categoryData.isEmpty) {
      return _buildEmptySection(theme, 'Where It Went');
    }

    final totalSpent = _spent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Where It Went',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 16,
            children: _categoryData.map((item) {
              final percentage = totalSpent > 0
                  ? (item.total / totalSpent * 100).round()
                  : 0;
              final maxTotal = _categoryData.first.total;
              final sizeRatio = maxTotal > 0
                  ? (item.total / maxTotal).clamp(0.5, 1.0)
                  : 0.5;
              final sealSize = 64.0 + (sizeRatio * 28.0);

              return SizedBox(
                width: sealSize + 8,
                child: Column(
                  children: [
                    CustomPaint(
                      painter: _SealPainter(
                        progress: percentage / 100.0,
                        sealColor: AppTheme.inkDark.withValues(alpha: 0.12),
                        arcColor: item.category.color.withValues(alpha: 0.7),
                        borderColor: AppTheme.ruled,
                      ),
                      child: SizedBox(
                        width: sealSize,
                        height: sealSize,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.category.icon,
                                style: TextStyle(fontSize: sealSize * 0.28),
                              ),
                              Text(
                                '$percentage%',
                                style: _mono(
                                  fontSize: sealSize * 0.14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.inkDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.category.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatRupees(item.total),
                      style: _mono(fontSize: 9, color: AppTheme.inkFaded),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptBoard(ThemeData theme) {
    if (_topMerchants.isEmpty) {
      return _buildEmptySection(theme, 'Top Merchants');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Top Merchants',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.parchment.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_topMerchants.length, (i) {
              final merchant = _topMerchants[i];
              final rotation = [-0.03, 0.025, -0.015, 0.035, -0.02][i % 5];

              return Transform.rotate(
                angle: rotation,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.parchmentLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.ruled.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.inkDark.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.inkRed.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${i + 1}',
                            style: _mono(
                              fontSize: 9,
                              color: AppTheme.inkFaded.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        merchant.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.inkDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 0.5,
                        color: AppTheme.ruled.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRupees(merchant.total),
                        style: _mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${merchant.count} txn${merchant.count == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppTheme.inkFaded,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTallyMarks(ThemeData theme) {
    final maxVal = _dowTotals.values.isEmpty
        ? 1
        : _dowTotals.values.reduce(math.max);
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
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          decoration: BoxDecoration(
            color: AppTheme.parchment,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.ruled, width: 0.5),
            boxShadow: const [_shadowMedium],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final dow = i + 1;
              final value = _dowTotals[dow] ?? 0;
              final proportion = maxVal > 0 ? value / maxVal : 0.0;
              final isWeekend = dow >= 6;
              final isHighest = value == maxVal && value > 0;
              final tallyCount = (proportion * 10).round().clamp(0, 10);

              return Expanded(
                child: Column(
                  children: [
                    if (value > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          formatRupees(value),
                          style: _mono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                    SizedBox(
                      height: 80,
                      width: 28,
                      child: CustomPaint(
                        painter: _TallyMarkPainter(
                          count: tallyCount,
                          inkColor: isWeekend
                              ? AppTheme.inkRed.withValues(alpha: 0.6)
                              : AppTheme.inkDark.withValues(alpha: 0.5),
                          isHighest: isHighest,
                          highlightColor: AppTheme.inkRed.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabels[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isWeekend
                            ? FontWeight.w700
                            : FontWeight.w500,
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
      ],
    );
  }

  Widget _buildTrendChart(ThemeData theme) {
    if (_trend.isEmpty) {
      return _buildEmptySection(theme, 'Trend');
    }

    final maxSpent = _trend
        .map((t) => t.spent)
        .reduce(math.max)
        .clamp(1, double.maxFinite.toInt());
    final rangeDays = _rangeEnd.difference(_rangeStart).inDays;
    final isWeekly = rangeDays < 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isWeekly ? 'Weekly breakdown' : 'Monthly breakdown',
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
            painter: _TrendBarPainter(
              data: _trend,
              maxValue: maxSpent,
              isWeekly: isWeekly,
              lineColor: AppTheme.ruled.withValues(alpha: 0.3),
              barColor: AppTheme.inkDark.withValues(alpha: 0.2),
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
              'No data for this period',
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

class _GraphPaperPainter extends CustomPainter {
  final Color lineColor;
  final double majorSpacing;

  _GraphPaperPainter({required this.lineColor, this.majorSpacing = 28});

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final minorPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.3;

    final minorSpacing = majorSpacing / 4;

    for (double y = 0; y < size.height; y += minorSpacing) {
      final isMajor = (y % majorSpacing).abs() < 0.5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }

    for (double x = 0; x < size.width; x += minorSpacing) {
      final isMajor = (x % majorSpacing).abs() < 0.5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPaperPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor;
}

class _TornEdgePainter extends CustomPainter {
  final Color color;

  _TornEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final rng = math.Random(99);
    path.moveTo(0, 0);

    for (double x = 0; x < size.width; x += 8) {
      final y = rng.nextDouble() * 4;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TornEdgePainter oldDelegate) => false;
}

class _SpendingPulsePainter extends CustomPainter {
  final Map<int, int> cumulative;
  final int totalDays;
  final int currentDay;
  final int budget;
  final Color inkColor;
  final Color budgetLineColor;
  final Color fillColor;

  _SpendingPulsePainter({
    required this.cumulative,
    required this.totalDays,
    required this.currentDay,
    required this.budget,
    required this.inkColor,
    required this.budgetLineColor,
    required this.fillColor,
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
    final safeTotalDays = totalDays.clamp(2, 365);

    final budgetPaint = Paint()
      ..color = budgetLineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final budgetY = padding.top + chartHeight * (1 - budget / yMax);
    double dx = padding.left;
    while (dx < size.width - padding.right) {
      canvas.drawLine(
        Offset(dx, budgetY),
        Offset(math.min(dx + 6, size.width - padding.right), budgetY),
        budgetPaint,
      );
      dx += 10;
    }

    if (cumulative.isEmpty) return;

    final path = Path();
    final fillPath = Path();
    bool started = false;

    for (int d = 1; d <= currentDay; d++) {
      final val = cumulative[d] ?? (d > 1 ? cumulative[d - 1] ?? 0 : 0);
      final x = padding.left + (d - 1) / (safeTotalDays - 1) * chartWidth;
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

    final lastX =
        padding.left + (currentDay - 1) / (safeTotalDays - 1) * chartWidth;
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
      final x = padding.left + (d - 1) / (safeTotalDays - 1) * chartWidth;
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

class _SealPainter extends CustomPainter {
  final double progress;
  final Color sealColor;
  final Color arcColor;
  final Color borderColor;

  _SealPainter({
    required this.progress,
    required this.sealColor,
    required this.arcColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(center, radius, Paint()..color = sealColor);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (progress > 0) {
      final arcRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }

    final innerRadius = radius - 6;
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = borderColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      sealColor != oldDelegate.sealColor ||
      arcColor != oldDelegate.arcColor;
}

class _TallyMarkPainter extends CustomPainter {
  final int count;
  final Color inkColor;
  final bool isHighest;
  final Color highlightColor;

  _TallyMarkPainter({
    required this.count,
    required this.inkColor,
    required this.isHighest,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHighest) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width + 4,
          height: size.height + 4,
        ),
        Paint()..color = highlightColor,
      );
    }

    if (count == 0) return;

    final paint = Paint()
      ..color = inkColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final markHeight = 12.0;
    final spacing = 4.0;
    final totalHeight = count <= 5
        ? count * markHeight + (count - 1) * spacing
        : 5 * markHeight + 4 * spacing;
    final startY = (size.height - totalHeight) / 2;
    final centerX = size.width / 2;

    final drawCount = count.clamp(0, 5);
    for (int i = 0; i < drawCount; i++) {
      final y = startY + i * (markHeight + spacing);
      canvas.drawLine(
        Offset(centerX - 6, y),
        Offset(centerX + 6, y + markHeight * 0.3),
        paint,
      );
    }

    if (count > 5) {
      final crossPaint = Paint()
        ..color = inkColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(centerX + 8, startY - 2),
        Offset(centerX - 8, startY + totalHeight + 2),
        crossPaint,
      );

      if (count > 5) {
        final remaining = count - 5;
        final startY2 = startY + totalHeight + spacing * 2;
        for (int i = 0; i < remaining.clamp(0, 5); i++) {
          final y = startY2 + i * (markHeight * 0.6 + 2);
          if (y + markHeight > size.height) break;
          canvas.drawLine(
            Offset(centerX - 5, y),
            Offset(centerX + 5, y + markHeight * 0.2),
            paint..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TallyMarkPainter oldDelegate) =>
      count != oldDelegate.count || isHighest != oldDelegate.isHighest;
}

class _TrendBarPainter extends CustomPainter {
  final List<({DateTime month, int spent, int income})> data;
  final int maxValue;
  final bool isWeekly;
  final Color lineColor;
  final Color barColor;
  final Color textColor;
  final Color valueColor;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  _TrendBarPainter({
    required this.data,
    required this.maxValue,
    required this.isWeekly,
    required this.lineColor,
    required this.barColor,
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
    if (barCount == 0) return;

    final barGroupWidth = chartWidth / barCount;
    final barWidth = barGroupWidth * 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < barCount; i++) {
      final item = data[i];
      final proportion = maxValue > 0 ? item.spent / maxValue : 0.0;
      final barHeight = proportion * chartHeight;

      final x =
          padding.left + i * barGroupWidth + (barGroupWidth - barWidth) / 2;
      final y = padding.top + chartHeight - barHeight;

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      canvas.drawRRect(barRect, Paint()..color = barColor);
      canvas.drawRRect(
        barRect,
        Paint()
          ..color = valueColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      String label;
      if (isWeekly) {
        label = '${item.month.day}/${item.month.month}';
      } else {
        label = _monthNames[item.month.month - 1];
      }

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(fontSize: 9, color: textColor),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - textPainter.width / 2,
          size.height - padding.bottom + 8,
        ),
      );

      if (item.spent > 0) {
        textPainter.text = TextSpan(
          text: '₹${formatIndianNumber(item.spent ~/ 100)}',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: valueColor.withValues(alpha: 0.7),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2, y - 14),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendBarPainter oldDelegate) => true;
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    final cursorOffset = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, formatted.length),
      ),
    );
  }
}

DateTime? _parseDate(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31 || year < 2020) {
    return null;
  }
  try {
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month) return null;
    return date;
  } catch (_) {
    return null;
  }
}

class _DateRangeInputSheet extends StatefulWidget {
  final String initialStart;
  final String initialEnd;

  const _DateRangeInputSheet({
    this.initialStart = '',
    this.initialEnd = '',
  });

  @override
  State<_DateRangeInputSheet> createState() => _DateRangeInputSheetState();
}

class _DateRangeInputSheetState extends State<_DateRangeInputSheet> {
  late TextEditingController _startController;
  late TextEditingController _endController;
  String? _error;

  TextStyle _mono({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.initialStart);
    _endController = TextEditingController(text: widget.initialEnd);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _submit() {
    final startText = _startController.text.trim();
    final endText = _endController.text.trim();
    final start = _parseDate(startText);
    final end = _parseDate(endText);

    if (start == null) {
      setState(() => _error = 'Invalid start date: "$startText"');
      return;
    }
    if (end == null) {
      setState(() => _error = 'Invalid end date: "$endText"');
      return;
    }
    if (end.isBefore(start)) {
      setState(() => _error = 'End date must be after start date');
      return;
    }
    if (end.isAfter(DateTime.now())) {
      setState(() => _error = 'End date cannot be in the future');
      return;
    }

    Navigator.pop(context, (start, end));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.ruled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Custom Date Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Format: DD/MM/YYYY',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: AppTheme.inkFaded,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _startController,
                      keyboardType: TextInputType.number,
                      style: _mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        hintStyle: _mono(
                          fontSize: 16,
                          color: AppTheme.ruled,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                        _DateInputFormatter(),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    '→',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.inkFaded,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: AppTheme.inkFaded,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _endController,
                      keyboardType: TextInputType.number,
                      style: _mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        hintStyle: _mono(
                          fontSize: 16,
                          color: AppTheme.ruled,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                        _DateInputFormatter(),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.inkRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Apply Range'),
            ),
          ),
        ],
      ),
    );
  }
}
