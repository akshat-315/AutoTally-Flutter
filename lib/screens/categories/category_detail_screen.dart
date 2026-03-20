import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/main.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/widgets/animated_entrance.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class CategoryDetailScreen extends StatefulWidget {
  final MockCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = true;
  String _activePreset = 'month';
  DateTime _rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rangeEnd = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
  int _totalSpent = 0;
  int _txCount = 0;
  List<MockTransaction> _transactions = [];

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
    _loadData();
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() => _activePreset = preset);

    switch (preset) {
      case 'month':
        _rangeStart = DateTime(now.year, now.month, 1);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'year':
        _rangeStart = DateTime(now.year, 1, 1);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'all':
        _rangeStart = DateTime(2020);
        _rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final txns = await queryService.transactionsForRange(_rangeStart, _rangeEnd);
    final filtered = txns
        .where((t) =>
            t.categoryId == widget.category.id && t.direction == 'debit')
        .toList();

    if (!mounted) return;

    setState(() {
      _transactions = filtered;
      _totalSpent = filtered.fold<int>(0, (sum, t) => sum + t.amount);
      _txCount = filtered.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.category.icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Text(widget.category.name),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildDateFilter(theme)),
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
                child: FadeSlideIn(
                  index: 0,
                  slideOffset: const Offset(0, 0.05),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: ext.surfaceGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.ruled, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.inkDark.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'TOTAL SPENT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.5,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatRupees(_totalSpent),
                              style: _mono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ext.debit,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 0.5,
                          height: 40,
                          color: AppTheme.ruled,
                        ),
                        Column(
                          children: [
                            Text(
                              'TRANSACTIONS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.5,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_txCount',
                              style: _mono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inkDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              if (_transactions.isEmpty)
                SliverFillRemaining(
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
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _transactions.length) return null;
                      final tx = _transactions[index];
                      return FadeSlideIn(
                        index: index + 1,
                        slideOffset: const Offset(0, 0.03),
                        child: TransactionRow(
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
                        ),
                      );
                    },
                    childCount: _transactions.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme) {
    final presets = [
      ('month', 'This Month'),
      ('year', 'This Year'),
      ('all', 'All Time'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: presets.map((p) {
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
                    color:
                        isActive ? AppTheme.inkDark : AppTheme.parchment,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? AppTheme.inkDark : AppTheme.ruled,
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p.$2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppTheme.parchmentLight
                            : AppTheme.inkFaded,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
