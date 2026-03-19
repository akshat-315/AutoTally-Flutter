import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/month_picker.dart';
import 'package:autotally_flutter/widgets/review_bell.dart';
import 'package:autotally_flutter/screens/transactions/transaction_detail_screen.dart';
import 'package:autotally_flutter/screens/merchants/merchant_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _currentMonth = DateTime(2026, 3);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  TextStyle _mono(TextStyle? base, {Color? color, double? fontSize, FontWeight? fontWeight}) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize ?? base?.fontSize,
      fontWeight: fontWeight ?? base?.fontWeight,
      color: color ?? base?.color,
      height: base?.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildHeroCard(theme),
              const SizedBox(height: 32),
              _buildTransactionsLedger(theme),
              const SizedBox(height: 32),
              _buildTopMerchants(theme),
              const SizedBox(height: 40),
            ],
          ),
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
          const ReviewBell(),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    final ext = context.appColors;
    final spent = PlaceholderData.totalSpentForMonth(
        _currentMonth.year, _currentMonth.month);
    final received = PlaceholderData.totalReceivedForMonth(
        _currentMonth.year, _currentMonth.month);
    final expenses = PlaceholderData.totalSpentForMonth(
        _currentMonth.year, _currentMonth.month);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.parchment,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.ruled, width: 0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: _RuledLinesPainter(
                  lineColor: AppTheme.ruled.withValues(alpha: 0.5),
                  spacing: 28,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 52),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await showMonthPicker(
                            context,
                            selected: _currentMonth,
                          );
                          if (picked != null) {
                            setState(() => _currentMonth = picked);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              PlaceholderData.monthLabel(_currentMonth),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Spent',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRupees(spent),
                        style: _mono(
                          theme.textTheme.headlineLarge,
                          color: theme.colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 0.5,
                        color: AppTheme.ruled,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 120,
                        height: 0.5,
                        color: AppTheme.ruled,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 40,
              right: 40,
              child: Row(
                children: [
                  _buildStatChip(
                    theme,
                    ext,
                    'Income',
                    formatRupees(received),
                    AppTheme.inkBlue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    theme,
                    ext,
                    'Expenses',
                    formatRupees(expenses),
                    AppTheme.inkRed,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildStatChip(ThemeData theme, AppThemeExtension ext,
      String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.parchmentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.ruled, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: _mono(
                theme.textTheme.bodyMedium,
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsLedger(ThemeData theme) {
    final ext = context.appColors;
    final txns = PlaceholderData.transactionsForMonth(
        _currentMonth.year, _currentMonth.month);
    final recent = txns.take(7).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 0.5, color: AppTheme.ruled),
          const SizedBox(height: 2),
          Container(height: 0.5, color: AppTheme.ruled),
          const SizedBox(height: 12),
          ...recent.map((tx) {
            final category = PlaceholderData.categoryById(tx.categoryId);
            final isDebit = tx.direction == 'debit';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SlidePageRoute(
                    child: TransactionDetailScreen(transaction: tx),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.ruled.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        _shortDay(tx.date),
                        style: _mono(
                          theme.textTheme.labelSmall,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (category?.color ?? const Color(0xFF9CA3AF))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: category != null
                            ? Text(category.icon,
                                style: const TextStyle(fontSize: 16))
                            : const Icon(Icons.help_outline_rounded,
                                size: 16, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.merchantName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            category?.name ?? 'Uncategorized',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isDebit ? '-' : '+'} ${formatRupees(tx.amount)}',
                      style: _mono(
                        theme.textTheme.bodyMedium,
                        color: isDebit ? ext.debit : ext.credit,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopMerchants(ThemeData theme) {
    final data = PlaceholderData.topMerchantsForMonth(
        _currentMonth.year, _currentMonth.month);

    if (data.isEmpty) return const SizedBox.shrink();

    final topFive = data.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frequent Merchants',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 0.5, color: AppTheme.ruled),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topFive.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = topFive[index];
                final category =
                    PlaceholderData.categoryById(item.merchant.categoryId);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        child: MerchantDetailScreen(
                            merchant: item.merchant),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.parchment,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.ruled,
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category?.icon ?? '\u{1F4E6}',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 60,
                        child: Text(
                          item.merchant.display,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]}\n${date.day}';
  }
}

class _RuledLinesPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;

  _RuledLinesPainter({required this.lineColor, this.spacing = 28});

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
  bool shouldRepaint(covariant _RuledLinesPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor || spacing != oldDelegate.spacing;
}
