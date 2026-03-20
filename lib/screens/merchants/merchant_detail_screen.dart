import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/main.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/category_picker.dart';
import 'package:autotally_flutter/widgets/transaction_row.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class MerchantDetailScreen extends StatefulWidget {
  final MockMerchant merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  State<MerchantDetailScreen> createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  late int? _categoryId;
  late bool _isP2p;
  late TextEditingController _nameController;
  bool _isLoading = true;
  List<MockTransaction> _merchantTxns = [];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.merchant.categoryId;
    _isP2p = widget.merchant.isP2p;
    _nameController =
        TextEditingController(text: widget.merchant.displayName ?? widget.merchant.name);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txns = await queryService.transactionsForMerchant(widget.merchant.id);
    if (!mounted) return;
    setState(() {
      _merchantTxns = txns;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = PlaceholderData.categoryById(_categoryId);

    final merchantTxns = _merchantTxns;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.merchant.display),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(theme, category),
            const SizedBox(height: 16),
            _buildEditSection(theme),
            const SizedBox(height: 24),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              _buildTransactionHistory(theme, merchantTxns),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, MockCategory? category) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (category?.color ?? const Color(0xFF9E9E9E))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    category?.icon ?? '?',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.merchant.display,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.merchant.vpa != null)
                      Text(
                        widget.merchant.vpa!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Category: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showCategoryPicker(context,
                      selectedId: _categoryId);
                  if (picked != null && mounted) {
                    setState(() => _categoryId = picked.id);
                    await queryService.updateMerchantCategory(
                        widget.merchant.id, picked.id);
                    if (mounted) _loadTransactions();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (category?.color ?? const Color(0xFF9E9E9E))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category?.icon ?? '?',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        category?.name ?? 'Uncategorized',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Person, not a shop',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isP2p,
                onChanged: (v) {
                  setState(() => _isP2p = v);
                  queryService.updateMerchantP2p(widget.merchant.id, v);
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                icon: Icons.receipt_outlined,
                label: '${widget.merchant.transactionCount} transactions',
                theme: theme,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.payments_outlined,
                label: formatRupees(widget.merchant.totalSpent),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Name',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter display name',
              suffixIcon: IconButton(
                icon: Icon(Icons.check_rounded,
                    color: theme.colorScheme.primary, size: 20),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  final name = _nameController.text.trim();
                  if (name.isNotEmpty) {
                    queryService.updateMerchantDisplayName(
                        widget.merchant.id, name);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(
      ThemeData theme, List<MockTransaction> txns) {
    final grouped = PlaceholderData.groupByDate(txns);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Transactions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (txns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No transactions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...entry.value.map((tx) => TransactionRow(
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
                )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
