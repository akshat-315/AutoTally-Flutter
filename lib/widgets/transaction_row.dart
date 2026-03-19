import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';

class TransactionRow extends StatelessWidget {
  final MockTransaction transaction;
  final VoidCallback? onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.appColors;
    final category = PlaceholderData.categoryById(transaction.categoryId);
    final isDebit = transaction.direction == 'debit';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildCategoryIcon(category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(category),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatRupeesWithSign(transaction.amount, transaction.direction),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDebit ? ext.debit : ext.credit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(MockCategory? category) {
    if (category == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(category.icon, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  String _subtitle(MockCategory? category) {
    final catName = category?.name ?? 'Uncategorized';
    final dateStr = PlaceholderData.shortDate(transaction.date);
    return '$catName \u00B7 $dateStr';
  }
}
