import 'package:flutter/material.dart';
import 'package:autotally_flutter/data/placeholder_data.dart';
import 'package:autotally_flutter/widgets/review_panel.dart';

class ReviewBell extends StatelessWidget {
  const ReviewBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = PlaceholderData.totalReviewCount;

    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          '$count',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.notifications_outlined, size: 24),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const ReviewPanel(),
        );
      },
    );
  }
}
