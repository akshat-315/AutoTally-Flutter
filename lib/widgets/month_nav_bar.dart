import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';

class MonthNavBar extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onTap;
  final bool canGoNext;

  const MonthNavBar({
    super.key,
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    this.onTap,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            enabled: true,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Text(
                PlaceholderData.monthLabel(currentMonth),
                key: ValueKey(currentMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            enabled: canGoNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
