import 'package:flutter/material.dart';
import 'package:autotally_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:autotally_flutter/screens/transactions/transaction_list_screen.dart';
import 'package:autotally_flutter/screens/budgets/budgets_goals_screen.dart';
import 'package:autotally_flutter/screens/analytics/analytics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabData(
      label: 'Dashboard',
      activeIcon: Icons.menu_book_rounded,
      inactiveIcon: Icons.menu_book_outlined,
    ),
    _TabData(
      label: 'Transactions',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
    _TabData(
      label: 'Budgets',
      activeIcon: Icons.savings_rounded,
      inactiveIcon: Icons.savings_outlined,
    ),
    _TabData(
      label: 'Analytics',
      activeIcon: Icons.bar_chart_rounded,
      inactiveIcon: Icons.bar_chart_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          TransactionListScreen(),
          BudgetsGoalsScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTabChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TabData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _TabData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabData> tabs;
  final ValueChanged<int> onTabChanged;

  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Column(
            children: [
              _buildGradientIndicator(context),
              Expanded(
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (i) => _buildTab(context, i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientIndicator(BuildContext context) {
    final indicatorColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          const indicatorWidth = 32.0;
          final left =
              tabWidth * currentIndex + (tabWidth - indicatorWidth) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: left,
                child: Container(
                  width: indicatorWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final theme = Theme.of(context);
    final tab = tabs[index];
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                isActive ? tab.activeIcon : tab.inactiveIcon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}
