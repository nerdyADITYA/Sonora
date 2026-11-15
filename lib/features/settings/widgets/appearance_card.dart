import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../app/theme/theme_mode_controller.dart';

/// Light, dark, or follow the phone's setting.
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Theme', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Phone follows your One UI dark mode setting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_android),
                  label: Text('Phone'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ],
        ),
      ),
    );
  }
}
