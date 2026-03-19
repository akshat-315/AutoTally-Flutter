import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/category_picker.dart';
import 'package:autotally_flutter/widgets/gradient_card.dart';
import 'package:autotally_flutter/screens/merchants/merchant_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class TransactionDetailScreen extends StatefulWidget {
  final MockTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late int? _categoryId;
  bool _smsExpanded = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.transaction.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.appColors;
    final tx = widget.transaction;
    final isDebit = tx.direction == 'debit';
    final category = PlaceholderData.categoryById(_categoryId);
    final merchant = PlaceholderData.merchantById(tx.merchantId);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(theme, ext, tx, isDebit, category),
            const SizedBox(height: 16),
            _buildDetailCard(theme, ext, tx, category, merchant),
            const SizedBox(height: 16),
            _buildRawSmsSection(theme, tx),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, AppThemeExtension ext,
      MockTransaction tx, bool isDebit, MockCategory? category) {
    final catColor = category?.color ?? const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withValues(alpha: 0.2),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: catColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            tx.merchantName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDebit
                    ? Icons.arrow_outward_rounded
                    : Icons.arrow_downward_rounded,
                size: 20,
                color: isDebit ? ext.debit : ext.credit,
              ),
              const SizedBox(width: 4),
              Text(
                formatRupees(tx.amount),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDebit ? ext.debit : ext.credit,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked =
                  await showCategoryPicker(context, selectedId: _categoryId);
              if (picked != null) {
                setState(() => _categoryId = picked.id);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: catColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category?.icon ?? '?',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    category?.name ?? 'Uncategorized',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(tx.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(ThemeData theme, AppThemeExtension ext,
      MockTransaction tx, MockCategory? category, MockMerchant? merchant) {
    return GradientCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (merchant != null)
            _DetailRow(
              label: 'Merchant',
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      child: MerchantDetailScreen(merchant: merchant),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      merchant.display,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            )
          else
            _DetailRow(
              label: 'Merchant',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unknown Merchant',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Assign',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _divider(theme),
          if (tx.categorySource != null)
            _DetailRow(
              label: 'Source',
              value: _categorySourceLabel(tx.categorySource!),
            ),
          if (tx.categorySource != null) _divider(theme),
          _DetailRow(label: 'Bank', value: tx.bank),
          if (tx.accountLast4 != null) ...[
            _divider(theme),
            _DetailRow(label: 'Account', value: 'xx${tx.accountLast4}'),
          ],
          if (tx.vpa != null) ...[
            _divider(theme),
            _DetailRow(label: 'VPA', value: tx.vpa!),
          ],
          if (tx.upiRef != null) ...[
            _divider(theme),
            _DetailRow(label: 'UPI Ref', value: tx.upiRef!),
          ],
          if (tx.isP2p) ...[
            _divider(theme),
            _DetailRow(
              label: 'Type',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF78909C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'P2P Transfer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF78909C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRawSmsSection(ThemeData theme, MockTransaction tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _smsExpanded = !_smsExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.sms_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Original SMS',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _smsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _smsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${tx.smsSender}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tx.rawSms,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
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

  Widget _divider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
      indent: 16,
      endIndent: 16,
    );
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$min $ampm';
  }

  String _categorySourceLabel(String source) {
    switch (source) {
      case 'auto_vpa':
        return 'Auto (VPA match)';
      case 'auto_merchant':
        return 'Auto (merchant default)';
      case 'user_override':
        return 'You set this';
      default:
        return source;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _DetailRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: child ??
                Text(
                  value ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
