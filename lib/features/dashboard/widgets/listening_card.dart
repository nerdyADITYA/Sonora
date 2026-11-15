import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/listening_status.dart';
import '../../listening/providers/listening_controller.dart';
import '../../recognition/recognition_error_copy.dart';

/// Ambient listening on/off with live status from the native service.
class ListeningCard extends ConsumerWidget {
  const ListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(listeningControllerProvider);
    final controller = ref.read(listeningControllerProvider.notifier);
    final status = state.status;
    final listening = state.listening;
    final (title, subtitle, accent) = _describe(context, state);

    final interrupted = !listening && (status?.interrupted ?? false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: listening ? accent : AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    listening ? Icons.graphic_eq : Icons.mic_off_outlined,
                    color: listening
                        ? AppColors.onAccent
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
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
                Switch(
                  value: listening,
                  onChanged: status == null || state.toggling
                      ? null
                      : (on) => on ? controller.start() : controller.stop(),
                ),
              ],
            ),
            if (interrupted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (!(status?.batteryUnrestricted ?? true))
                      TextButton(
                        onPressed: controller.openBatterySettings,
                        child: const Text('Battery settings'),
                      ),
                    TextButton(
                      onPressed: controller.dismissInterruption,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static (String, String?, Color) _describe(
    BuildContext context,
    ListeningState state,
  ) {
    final status = state.status;
    if (status == null) return ('Checking…', null, AppColors.accent);

    if (!status.listening && status.interrupted && state.startError == null) {
      return (
        'Listening was stopped',
        status.batteryUnrestricted
            ? 'Android stopped Sonora in the background. Turn it back on to keep listening.'
            : 'One UI stopped Sonora to save battery. Turn it back on, and set '
                  'Battery to Unrestricted so it keeps running.',
        AppColors.warning,
      );
    }

    if (!status.listening) {
      final error = state.startError ?? status.lastError;
      return (
        state.toggling ? 'Starting…' : 'Not listening',
        recognitionErrorDetail(error) ??
            'Turn on to identify music around you automatically.',
        AppColors.accent,
      );
    }

    final usage = '${status.requestsToday}/${status.dailyBudget} checks today';
    final next = status.nextCheckAt == null
        ? null
        : 'Next check around ${TimeOfDay.fromDateTime(status.nextCheckAt!).format(context)}';

    return switch (status.phase) {
      ListeningPhase.listening => ('Listening…', usage, AppColors.accent),
      ListeningPhase.matching => ('Identifying…', usage, AppColors.accent),
      ListeningPhase.pausedBudget => (
        'Paused for today',
        'Daily limit of ${status.dailyBudget} checks reached. Turn off to stop the service.',
        AppColors.warning,
      ),
      ListeningPhase.offline => (
        'Waiting for internet',
        'Sonora needs a connection to identify songs. The microphone stays off until you\'re back online.',
        AppColors.warning,
      ),
      ListeningPhase.microphoneBlocked => (
        'Microphone blocked',
        'The microphone returned silence or is in use. Check the microphone toggle in Quick Settings.',
        AppColors.warning,
      ),
      _ => (
        'Listening for music',
        [
          ?next,
          usage,
          if (status.powerSave) 'battery saver: checking less often',
        ].join(' · '),
        AppColors.accent,
      ),
    };
  }
}
