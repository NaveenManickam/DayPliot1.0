import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../utils/app_strings.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key, required this.language});
  final String language;

  static const _items = <(String, IconData, Color, Color)>[
    ('task', Icons.check_circle_rounded, AppColors.coral, AppColors.coralPale),
    ('habit', Icons.local_fire_department_rounded, AppColors.yellow, AppColors.yellowPale),
    ('event', Icons.calendar_month_rounded, AppColors.mint, AppColors.mintPale),
    ('note', Icons.sticky_note_2_rounded, AppColors.blue, AppColors.bluePale),
    ('journal', Icons.menu_book_rounded, AppColors.coral, AppColors.coralPale),
    ('water', Icons.water_drop_rounded, AppColors.blue, AppColors.bluePale),
    ('exercise', Icons.fitness_center_rounded, AppColors.mint, AppColors.mintPale),
    ('sleep', Icons.nightlight_round, AppColors.blue, AppColors.bluePale),
    ('mood', Icons.mood_rounded, AppColors.yellow, AppColors.yellowPale),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(language);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: Text(strings.call('quick_add'), style: Theme.of(context).textTheme.titleLarge)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, item.$1),
                  child: Container(
                    decoration: BoxDecoration(color: item.$4, borderRadius: BorderRadius.circular(20)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(item.$2, color: item.$3, size: 25),
                      const SizedBox(height: 8),
                      Text(strings.call(item.$1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
