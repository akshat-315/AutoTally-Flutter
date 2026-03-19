import 'package:flutter/material.dart';

Future<DateTime?> showMonthPicker(BuildContext context,
    {required DateTime selected}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _MonthPickerSheet(selected: selected),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime selected;

  const _MonthPickerSheet({required this.selected});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _selectedMonth;
  late int _selectedYear;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final _now = DateTime(2026, 3, 19);

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year;
    _selectedMonth = widget.selected.month;
    _selectedYear = widget.selected.year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$_year',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: _year < _now.year ? () => setState(() => _year++) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isFuture =
                  _year > _now.year || (_year == _now.year && month > _now.month);
              final isSelected = month == _selectedMonth && _year == _selectedYear;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isFuture
                      ? null
                      : () => Navigator.pop(context, DateTime(_year, month)),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isFuture
                            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                            : isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
