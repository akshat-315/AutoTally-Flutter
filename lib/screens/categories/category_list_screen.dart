
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/main.dart';
import 'package:autotally_flutter/theme/app_theme.dart';
import 'package:autotally_flutter/utils/currency_formatter.dart';
import 'package:autotally_flutter/widgets/animated_entrance.dart';
import 'package:autotally_flutter/screens/categories/category_detail_screen.dart';
import 'package:autotally_flutter/utils/page_transitions.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  bool _isLoading = true;
  DateTime _rangeStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _rangeEnd = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
  String _activePreset = 'month';
  List<({MockCategory category, int total})> _categoryData = [];
  int _totalSpent = 0;

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

    final results = await Future.wait([
      queryService.spendByCategoryForRange(_rangeStart, _rangeEnd),
      queryService.rangeStats(_rangeStart, _rangeEnd),
    ]);

    if (!mounted) return;

    final stats = results[1]
        as ({int spent, int received, int txCount, int debitCount, int creditCount});

    setState(() {
      _categoryData =
          results[0] as List<({MockCategory category, int total})>;
      _totalSpent = stats.spent;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme)),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
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
            else if (_categoryData.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No spending data for this period',
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
                    if (index >= _categoryData.length) return null;
                    final item = _categoryData[index];
                    final percentage = _totalSpent > 0
                        ? (item.total / _totalSpent * 100)
                        : 0.0;
                    final maxTotal = _categoryData.first.total;
                    final proportion =
                        maxTotal > 0 ? item.total / maxTotal : 0.0;

                    return FadeSlideIn(
                      index: index,
                      slideOffset: const Offset(0, 0.05),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              child: CategoryDetailScreen(
                                category: item.category,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.parchment,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppTheme.ruled, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.inkDark.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.category.color
                                      .withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: item.category.color
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    item.category.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.category.name,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          formatRupees(item.total),
                                          style: _mono(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: proportion,
                                              backgroundColor: AppTheme.ruled
                                                  .withValues(alpha: 0.3),
                                              color: item.category.color
                                                  .withValues(alpha: 0.6),
                                              minHeight: 4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${percentage.round()}%',
                                          style: _mono(
                                            fontSize: 11,
                                            color: AppTheme.inkFaded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppTheme.ruled,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _categoryData.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Text(
        'Categories',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
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
