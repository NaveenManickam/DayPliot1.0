import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 13),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF9297AA), visualDensity: VisualDensity.compact),
                child: Text(action!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      );
}
