import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/platform/sonora_platform.dart';
import '../../onboarding/providers/privacy_consent_controller.dart';
import '../../onboarding/widgets/privacy_disclosure.dart';

/// The privacy policy, and agreeing to or withdrawing the microphone consent.
class PrivacySettingsCard extends ConsumerWidget {
  const PrivacySettingsCard({super.key});

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw consent?'),
        content: const Text(
          'Sonora stops listening straight away and won’t use the microphone '
          'until you agree again. Your history stays on this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(privacyConsentProvider.notifier).withdraw();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Consent withdrawn. Listening is off.'),
        action: SnackBarAction(
          label: 'App settings',
          onPressed: () =>
              ref.read(sonoraPlatformProvider).openBatterySettings(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreed = ref.watch(privacyConsentProvider).value;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            subtitle: const Text('What Sonora sends, and to whom'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => openPrivacyPolicy(context),
          ),
          if (agreed == true)
            ListTile(
              leading: const Icon(Icons.mic_off_outlined),
              title: const Text('Withdraw microphone consent'),
              subtitle: const Text(
                'Stops listening. Revoke the permission itself in app settings.',
              ),
              onTap: () => _withdraw(context, ref),
            )
          else if (agreed == false)
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: const Text('Review and agree'),
              subtitle: const Text('Needed before Sonora can identify songs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => PrivacyDisclosureScreen.open(context),
            ),
        ],
      ),
    );
  }
}
