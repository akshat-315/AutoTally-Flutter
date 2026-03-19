import 'package:flutter/material.dart';

class FilterChipRow extends StatelessWidget {
  final List<FilterChipData> chips;
  final Set<int> selectedIndices;
  final ValueChanged<int> onSelected;

  const FilterChipRow({
    super.key,
    required this.chips,
    required this.selectedIndices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final selected = selectedIndices.contains(index);
          return _buildChip(context, chip, selected, index);
        },
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, FilterChipData chip, bool selected, int index) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chip.icon != null) ...[
                  Text(chip.icon!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                ],
                Text(
                  chip.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FilterChipData {
  final String label;
  final String? icon;

  const FilterChipData({required this.label, this.icon});
}
