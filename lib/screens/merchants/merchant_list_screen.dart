import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/filter_chip_row.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/screens/merchants/merchant_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class MerchantListScreen extends StatefulWidget {
  const MerchantListScreen({super.key});

  @override
  State<MerchantListScreen> createState() => _MerchantListScreenState();
}

class _MerchantListScreenState extends State<MerchantListScreen> {
  String _searchQuery = '';
  final Set<int> _selectedFilters = {0};
  final _searchController = TextEditingController();

  static const _filterChips = <FilterChipData>[
    FilterChipData(label: 'All'),
    FilterChipData(label: 'Categorized'),
    FilterChipData(label: 'Uncategorized'),
    FilterChipData(label: 'P2P'),
  ];

  void _onFilterSelected(int index) {
    setState(() {
      if (index == 0) {
        _selectedFilters.clear();
        _selectedFilters.add(0);
        return;
      }
      _selectedFilters.remove(0);
      if (_selectedFilters.contains(index)) {
        _selectedFilters.remove(index);
      } else {
        _selectedFilters.add(index);
      }
      if (_selectedFilters.isEmpty) _selectedFilters.add(0);
    });
  }

  List<MockMerchant> get _filteredMerchants {
    var merchants = PlaceholderData.merchants.toList();

    if (_searchQuery.isNotEmpty) {
      merchants = merchants
          .where((m) =>
              m.display.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (m.vpa?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    if (!_selectedFilters.contains(0)) {
      merchants = merchants.where((m) {
        if (_selectedFilters.contains(1) && m.categoryId == null) return false;
        if (_selectedFilters.contains(2) && m.categoryId != null) return false;
        if (_selectedFilters.contains(3) && !m.isP2p) return false;
        return true;
      }).toList();
    }

    merchants.sort((a, b) => a.display.compareTo(b.display));
    return merchants;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final merchants = _filteredMerchants;
    final grouped = _groupAlphabetically(merchants);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchants'),
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
          const SizedBox(height: 8),
          Expanded(
            child: merchants.isEmpty
                ? Center(
                    child: Text(
                      'No merchants match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: grouped.length,
                    itemBuilder: (context, sectionIndex) {
                      final letter = grouped.keys.elementAt(sectionIndex);
                      final sectionMerchants = grouped[letter]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              letter,
                              style:
                                  theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ...sectionMerchants.map((m) => _MerchantRow(
                                merchant: m,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(
                                      child:
                                          MerchantDetailScreen(merchant: m),
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

  Map<String, List<MockMerchant>> _groupAlphabetically(
      List<MockMerchant> merchants) {
    final grouped = <String, List<MockMerchant>>{};
    for (final m in merchants) {
      final letter = m.display[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(m);
    }
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

class _MerchantRow extends StatelessWidget {
  final MockMerchant merchant;
  final VoidCallback onTap;

  const _MerchantRow({required this.merchant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = PlaceholderData.categoryById(merchant.categoryId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (category?.color ?? const Color(0xFF9E9E9E))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: category != null
                      ? Text(category.icon,
                          style: const TextStyle(fontSize: 18))
                      : const Icon(Icons.help_outline_rounded,
                          size: 20, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            merchant.display,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (merchant.isP2p) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF78909C)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P2P',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: const Color(0xFF78909C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (merchant.vpa != null)
                      Text(
                        merchant.vpa!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupees(merchant.totalSpent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${merchant.transactionCount} txns',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}
