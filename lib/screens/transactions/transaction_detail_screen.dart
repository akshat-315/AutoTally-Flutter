import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/category_picker.dart';
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

  TextStyle _mono({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
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
          children: [
            _buildLedgerEntry(theme, ext, tx, isDebit, category, merchant),
            const SizedBox(height: 16),
            _buildSmsAttachment(theme, tx),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerEntry(ThemeData theme, AppThemeExtension ext,
      MockTransaction tx, bool isDebit, MockCategory? category,
      MockMerchant? merchant) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.ruled, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C2416),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _LedgerPagePainter(
          lineColor: AppTheme.ruled.withValues(alpha: 0.3),
          marginColor: AppTheme.inkRed.withValues(alpha: 0.18),
          spacing: 28,
          marginX: 72,
        ),
        foregroundPainter: _PaperGrainPainter(
          color: AppTheme.inkDark.withValues(alpha: 0.025),
          density: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildAmountHeader(theme, ext, tx, isDebit),
            const SizedBox(height: 20),
            _buildEntryRow(theme, 'Date', _formatDateTime(tx.date)),
            if (merchant != null)
              _buildMerchantRow(theme, merchant)
            else
              _buildEntryRow(theme, 'Merchant', tx.merchantName),
            _buildCategoryRow(theme, category),
            if (tx.categorySource != null)
              _buildEntryRow(
                  theme, 'Source', _categorySourceLabel(tx.categorySource!)),
            _buildEntryRow(theme, 'Bank', tx.bank),
            if (tx.accountLast4 != null)
              _buildEntryRow(theme, 'Account', 'xx${tx.accountLast4}'),
            if (tx.vpa != null)
              _buildEntryRow(theme, 'VPA', tx.vpa!),
            if (tx.upiRef != null)
              _buildEntryRow(theme, 'UPI Ref', tx.upiRef!),
            if (tx.isP2p)
              _buildEntryRow(theme, 'Type', 'P2P Transfer'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(height: 0.5, color: AppTheme.ruled),
                  const SizedBox(height: 2),
                  Container(height: 0.5, color: AppTheme.ruled),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountHeader(ThemeData theme, AppThemeExtension ext,
      MockTransaction tx, bool isDebit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              isDebit ? 'Dr.' : 'Cr.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isDebit ? '-' : '+'} ${formatRupees(tx.amount)}',
                  style: _mono(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDebit ? ext.debit : ext.credit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final valueText = value;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: valueText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();

                final dotsWidth =
                    constraints.maxWidth - textPainter.width - 8;

                return Row(
                  children: [
                    if (dotsWidth > 10)
                      SizedBox(
                        width: dotsWidth,
                        height: 12,
                        child: CustomPaint(
                          painter: _DottedLinePainter(color: AppTheme.ruled),
                        ),
                      ),
                    if (dotsWidth > 10) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        valueText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantRow(ThemeData theme, MockMerchant merchant) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            SlidePageRoute(
              child: MerchantDetailScreen(merchant: merchant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  'Merchant',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                merchant.display,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.ruled,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(ThemeData theme, MockCategory? category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked =
              await showCategoryPicker(context, selectedId: _categoryId);
          if (picked != null) {
            setState(() => _categoryId = picked.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  'Category',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.inkFaded.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.ruled,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category?.name ?? 'Uncategorized',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmsAttachment(ThemeData theme, MockTransaction tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ruled, width: 0.5),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _smsExpanded = !_smsExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.sms_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Original SMS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _smsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                      color: AppTheme.parchmentLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.ruled.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tx.rawSms,
                      style: _mono(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ).copyWith(height: 1.6),
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

class _LedgerPagePainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final double spacing;
  final double marginX;

  _LedgerPagePainter({
    required this.lineColor,
    required this.marginColor,
    this.spacing = 28,
    this.marginX = 72,
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
  bool shouldRepaint(covariant _LedgerPagePainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      spacing != oldDelegate.spacing ||
      marginColor != oldDelegate.marginColor ||
      marginX != oldDelegate.marginX;
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

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    const gap = 3.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawCircle(Offset(x, y), 0.6, paint);
      x += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
