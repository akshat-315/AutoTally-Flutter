import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/widgets/filter_chip_row.dart';
import 'package:autotally_flutter/widgets/month_picker.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';
import 'package:autotally_flutter/widgets/animated_entrance.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  DateTime _currentMonth = DateTime(2026, 3);
  String _searchQuery = '';
  bool _isSearching = false;
  final Set<int> _selectedFilters = {0};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  static final _filterChips = <FilterChipData>[
    const FilterChipData(label: 'All'),
    const FilterChipData(label: 'Debits'),
    const FilterChipData(label: 'Credits'),
    ...PlaceholderData.categories.map(
      (c) => FilterChipData(label: c.name),
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

  void _openSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txns = _filteredTransactions;
    final grouped = PlaceholderData.groupByDate(txns);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search merchants...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : _buildMonthTitle(theme),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              onPressed: _closeSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 22),
              onPressed: _openSearch,
            ),
            const ReviewBell(),
          ],
        ],
      ),
      body: txns.isEmpty
          ? _buildEmptyState(theme)
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
                if (mounted) setState(() {});
              },
              color: AppTheme.inkDark,
              backgroundColor: AppTheme.parchment,
              displacement: 40,
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: FilterChipRow(
                      chips: _filterChips,
                      selectedIndices: _selectedFilters,
                      onSelected: _onFilterSelected,
                    ),
                  ),
                ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, sectionIndex) {
                            final dateLabel =
                                grouped.keys.elementAt(sectionIndex);
                            final sectionTxns = grouped[dateLabel]!;

                            int rowIndex = 0;
                            for (int s = 0; s < sectionIndex; s++) {
                              rowIndex += grouped.values.elementAt(s).length + 1;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeSlideIn(
                                  index: rowIndex,
                                  child: _buildDateHeader(theme, dateLabel),
                                ),
                                ...sectionTxns.asMap().entries.map((entry) {
                                  final tx = entry.value;
                                  return FadeSlideIn(
                                    index: rowIndex + entry.key + 1,
                                    child: TransactionRow(
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
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                          childCount: grouped.length,
                        ),
                      ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
            ),
    );
  }

  Widget _buildMonthTitle(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        final picked = await showMonthPicker(
          context,
          selected: _currentMonth,
        );
        if (picked != null) setState(() => _currentMonth = picked);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _goToPrevMonth,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              PlaceholderData.monthLabel(_currentMonth),
              key: ValueKey(_currentMonth),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canGoNext ? _goToNextMonth : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: _canGoNext
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

Widget _buildDateHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.parchment,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.ruled, width: 0.5),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(height: 0.5, color: AppTheme.ruled),
                const SizedBox(height: 2),
                Container(height: 0.5, color: AppTheme.ruled),
              ],
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

