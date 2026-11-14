import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';

/// Empty state for the most recent recognition. Real data arrives with history (Phase 4).
class LastDiscoveryCard extends StatelessWidget {
  const LastDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAST DISCOVERY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.music_note_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No songs yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Music Sonora recognises will appear here.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
