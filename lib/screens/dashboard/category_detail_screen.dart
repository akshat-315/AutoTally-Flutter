import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/main.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/month_nav_bar.dart';
import 'package:autotally_flutter/widgets/month_picker.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class CategoryDetailScreen extends StatefulWidget {
  final MockCategory category;
  final DateTime initialMonth;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.initialMonth,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late DateTime _currentMonth;
  bool _isLoading = true;
  List<MockTransaction> _txns = [];

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allTxns = await queryService.transactionsForMonth(
      _currentMonth.year, _currentMonth.month,
    );
    if (!mounted) return;
    setState(() {
      _txns = allTxns
          .where((t) =>
              t.categoryId == widget.category.id && t.direction == 'debit')
          .toList();
      _isLoading = false;
    });
  }

  void _goToPrevMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    _loadData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nowMonth = DateTime(now.year, now.month);
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (next.year < nowMonth.year ||
        (next.year == nowMonth.year && next.month <= nowMonth.month)) {
      _currentMonth = next;
      _loadData();
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.appColors;

    final txns = _txns;
    final totalSpent = txns.fold<int>(0, (sum, t) => sum + t.amount);
    final grouped = PlaceholderData.groupByDate(txns);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.icon} ${widget.category.name}'),
      ),
      body: Column(
        children: [
          MonthNavBar(
            currentMonth: _currentMonth,
            onPrevious: _goToPrevMonth,
            onNext: _goToNextMonth,
            canGoNext: _canGoNext,
            onTap: () async {
              final picked = await showMonthPicker(
                context,
                selected: _currentMonth,
              );
              if (picked != null) {
                _currentMonth = picked;
                _loadData();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  formatRupees(totalSpent),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ext.debit,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${txns.length} transactions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.inkDark,
                      strokeWidth: 2,
                    ),
                  )
                : txns.isEmpty
                ? Center(
                    child: Text(
                      'No ${widget.category.name} spending this month.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: grouped.length,
                    itemBuilder: (context, sectionIndex) {
                      final dateLabel = grouped.keys.elementAt(sectionIndex);
                      final sectionTxns = grouped[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              dateLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...sectionTxns.map((tx) => TransactionRow(
                                transaction: tx,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      child:
                                          TransactionDetailScreen(transaction: tx),
                                    ),
                                  );
                                },
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
