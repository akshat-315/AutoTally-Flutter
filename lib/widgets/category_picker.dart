import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';

Future<MockCategory?> showCategoryPicker(BuildContext context,
    {int? selectedId}) {
  return showModalBottomSheet<MockCategory>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CategoryPickerSheet(selectedId: selectedId),
  );
}

class _CategoryPickerSheet extends StatelessWidget {
  final int? selectedId;

  const _CategoryPickerSheet({this.selectedId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: PlaceholderData.categories.length,
            itemBuilder: (context, index) {
              final category = PlaceholderData.categories[index];
              final isSelected = category.id == selectedId;
              return _CategoryTile(
                category: category,
                isSelected: isSelected,
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Manage Categories'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final MockCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? category.color.withValues(alpha: 0.15)
                : theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? category.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 22)),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? category.color
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
