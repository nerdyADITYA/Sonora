import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../core/models/listening_status.dart';
import '../../listening/providers/listening_controller.dart';
import '../../onboarding/providers/privacy_consent_controller.dart';
import '../../onboarding/widgets/privacy_disclosure.dart';
import '../../recognition/recognition_error_copy.dart';
import '../../../shared/widgets/pop.dart';

/// Ambient listening on/off with live status from the native service.
class ListeningCard extends ConsumerWidget {
  const ListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = context.palette;
    final state = ref.watch(listeningControllerProvider);
    final controller = ref.read(listeningControllerProvider.notifier);
    final status = state.status;
    final listening = state.listening;
    final (title, subtitle, tone) = _describe(context, state);

    final interrupted = !listening && (status?.interrupted ?? false);
    // Lime while listening; text on it is always dark.
    final onCard = listening ? p.onPop : p.textPrimary;
    final onCardSoft = listening
        ? p.onPop.withValues(alpha: 0.72)
        : p.textSecondary;

    return PopCard(
      color: listening ? p.accent : p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: ShapeDecoration(
                  color: listening ? p.surface : p.surfaceHigh,
                  shape: CircleBorder(side: BorderSide(color: p.ink, width: 2)),
                ),
                child: Icon(
                  listening ? Icons.graphic_eq : Icons.mic_off_outlined,
                  color: listening ? p.textPrimary : p.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: tone == null || listening ? onCard : tone,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onCardSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: listening,
                onChanged: status == null || state.toggling
                    ? null
                    : (on) async {
                        if (!on) return controller.stop();
                        // Skipped the disclosure at setup: ask for it first.
                        final agreed =
                            ref.read(privacyConsentProvider).value ?? true;
                        if (agreed ||
                            await PrivacyDisclosureScreen.open(context)) {
                          await controller.start();
                        }
                      },
              ),
            ],
          ),
          if (interrupted)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!(status?.batteryUnrestricted ?? true))
                    FilledButton(
                      onPressed: controller.openBatterySettings,
                      child: const Text('Battery settings'),
                    ),
                  OutlinedButton(
                    onPressed: controller.dismissInterruption,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Title, detail, and a warning colour when something needs attention.
  static (String, String?, Color?) _describe(
    BuildContext context,
    ListeningState state,
  ) {
    final status = state.status;
    final warning = context.palette.warning;
    if (status == null) return ('Checking…', null, null);

    if (!status.listening && status.interrupted && state.startError == null) {
      return (
        'Listening was stopped',
        status.batteryUnrestricted
            ? 'Android stopped Sonora in the background. Turn it back on to keep listening.'
            : 'One UI stopped Sonora to save battery. Turn it back on, and set '
                  'Battery to Unrestricted so it keeps running.',
        warning,
      );
    }

    if (!status.listening) {
      final error = state.startError ?? status.lastError;
      return (
        state.toggling ? 'Starting…' : 'Not listening',
        recognitionErrorDetail(error) ??
            'Turn on to identify music around you automatically.',
        null,
      );
    }

    final usage = '${status.requestsToday}/${status.dailyBudget} checks today';
    final next = status.nextCheckAt == null
        ? null
        : 'Next check around ${TimeOfDay.fromDateTime(status.nextCheckAt!).format(context)}';

    return switch (status.phase) {
      ListeningPhase.listening => ('Listening…', usage, null),
      ListeningPhase.matching => ('Identifying…', usage, null),
      ListeningPhase.pausedBudget => (
        'Paused for today',
        'Daily limit of ${status.dailyBudget} checks reached. Turn off to stop the service.',
        warning,
      ),
      ListeningPhase.offline => (
        'Waiting for internet',
        'Sonora needs a connection to identify songs. The microphone stays off until you\'re back online.',
        warning,
      ),
      ListeningPhase.microphoneBlocked => (
        'Microphone blocked',
        'The microphone returned silence or is in use. Check the microphone toggle in Quick Settings.',
        warning,
      ),
      _ => (
        'Listening for music',
        [
          ?next,
          usage,
          if (status.powerSave) 'battery saver: checking less often',
        ].join(' · '),
        null,
      ),
    };
  }
}
