import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/widgets/filter_chip_row.dart';
import 'package:autotally_flutter/widgets/month_nav_bar.dart';
import 'package:autotally_flutter/widgets/month_picker.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTime _currentMonth = DateTime(2026, 3);
  String _searchQuery = '';
  final Set<int> _selectedFilters = {0};
  final _searchController = TextEditingController();

  static final _filterChips = <FilterChipData>[
    const FilterChipData(label: 'All'),
    const FilterChipData(label: 'Debits'),
    const FilterChipData(label: 'Credits'),
    ...PlaceholderData.categories.map(
      (c) => FilterChipData(label: c.name, icon: c.icon),
    ),
    const FilterChipData(label: 'Uncategorized'),
    const FilterChipData(label: 'P2P'),
  ];

  void _onFilterSelected(int index) {
    setState(() {
      if (index == 0) {
        _selectedFilters.clear();
        _selectedFilters.add(0);
        return;
      }

      _selectedFilters.remove(0);

      if (index == 1 || index == 2) {
        _selectedFilters.remove(index == 1 ? 2 : 1);
      }

      if (_selectedFilters.contains(index)) {
        _selectedFilters.remove(index);
      } else {
        _selectedFilters.add(index);
      }

      if (_selectedFilters.isEmpty) _selectedFilters.add(0);
    });
  }

  List<MockTransaction> get _filteredTransactions {
    var txns = PlaceholderData.transactionsForMonth(
        _currentMonth.year, _currentMonth.month);

    if (_searchQuery.isNotEmpty) {
      txns = txns
          .where((t) =>
              t.merchantName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilters.contains(0)) return txns;

    return txns.where((t) {
      if (_selectedFilters.contains(1) && t.direction != 'debit') return false;
      if (_selectedFilters.contains(2) && t.direction != 'credit') return false;

      final categoryFilters = _selectedFilters.where((i) => i >= 3 && i <= 12);
      if (categoryFilters.isNotEmpty) {
        final catIds = categoryFilters.map((i) => i - 2).toSet();
        if (!catIds.contains(t.categoryId)) return false;
      }

      if (_selectedFilters.contains(13) && t.categoryId != null) return false;
      if (_selectedFilters.contains(14) && !t.isP2p) return false;

      return true;
    }).toList();
  }

  void _goToPrevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    final now = DateTime(2026, 3);
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (next.year < now.year ||
        (next.year == now.year && next.month <= now.month)) {
      setState(() => _currentMonth = next);
    }
  }

  bool get _canGoNext {
    final now = DateTime(2026, 3);
    return _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;
    final grouped = PlaceholderData.groupByDate(txns);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: const [ReviewBell()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search merchants...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilterChipRow(
            chips: _filterChips,
            selectedIndices: _selectedFilters,
            onSelected: _onFilterSelected,
          ),
          const SizedBox(height: 4),
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
              if (picked != null) setState(() => _currentMonth = picked);
            },
          ),
          Expanded(
            child: txns.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: grouped.length,
                    itemBuilder: (context, sectionIndex) {
                      final dateLabel =
                          grouped.keys.elementAt(sectionIndex);
                      final sectionTxns = grouped[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              dateLabel,
                              style:
                                  theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...sectionTxns.map((tx) => TransactionRow(
                                transaction: tx,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      child: TransactionDetailScreen(
                                          transaction: tx),
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

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilters = !_selectedFilters.contains(0) || _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_off_rounded
                  : Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No transactions match your filters.'
                  : 'No transactions this month.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear();
                    _selectedFilters.add(0);
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
