import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/platform/sonora_platform.dart';
import '../../listening/providers/listening_controller.dart';

/// The Quick Settings tile and One UI's battery setting for Sonora.
class ListeningSettingsCard extends ConsumerWidget {
  const ListeningSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(listeningControllerProvider).status;
    final unrestricted = status?.batteryUnrestricted ?? true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('Add Quick Settings tile'),
            subtitle: const Text(
              'Turn listening on or off from the notification panel.',
            ),
            onTap: () => _addTile(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full_outlined),
            title: const Text('Battery usage'),
            subtitle: Text(
              unrestricted
                  ? 'Unrestricted. One UI won\'t stop Sonora while it listens.'
                  : 'Optimised. One UI may stop listening in the background. '
                        'Tap, then Battery › Unrestricted.',
              style: unrestricted
                  ? null
                  : const TextStyle(color: AppColors.warning),
            ),
            onTap: ref
                .read(listeningControllerProvider.notifier)
                .openBatterySettings,
          ),
        ],
      ),
    );
  }

  Future<void> _addTile(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    String result;
    try {
      result = await ref.read(sonoraPlatformProvider).requestAddTile();
    } on PlatformFailure {
      result = 'unavailable';
    }
    final message = switch (result) {
      'added' => 'Tile added to Quick Settings.',
      'already_added' => 'The Sonora tile is already in Quick Settings.',
      'not_added' => 'Tile not added.',
      _ => 'Swipe down twice, tap the pencil, and drag the Sonora tile into place.',
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
