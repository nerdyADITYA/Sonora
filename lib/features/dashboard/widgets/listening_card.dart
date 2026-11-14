import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';

/// Shows the listening state. The switch stays disabled until the native
/// listening service exists (Phase 3); it never pretends to listen.
class ListeningCard extends ConsumerWidget {
  const ListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(listeningStatusProvider);

    final (title, subtitle, listening, available) = switch (status) {
      AsyncData(:final value) => (
        value.listening ? 'Listening' : 'Not listening',
        value.available
            ? 'Sonora identifies music playing around you.'
            : 'Ambient listening arrives in a later release.',
        value.listening,
        value.available,
      ),
      AsyncError() => (
        'Status unavailable',
        'Could not reach the native service.',
        false,
        false,
      ),
      _ => ('Checking…', '', false, false),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: listening ? AppColors.accent : AppColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                listening ? Icons.graphic_eq : Icons.mic_off_outlined,
                color: listening ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(value: listening, onChanged: available ? (_) {} : null),
          ],
        ),
      ),
    );
  }
}
