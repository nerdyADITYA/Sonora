import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../providers/recognition_controller.dart';

/// Manual "identify this song" control with status and error copy.
class RecognizeCard extends ConsumerWidget {
  const RecognizeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(recognitionControllerProvider);
    final controller = ref.read(recognitionControllerProvider.notifier);
    final (headline, detail, color) = _describe(state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'IDENTIFY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (state.isBusy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 3),
            ],
            const SizedBox(height: 16),
            state.isBusy
                ? OutlinedButton.icon(
                    onPressed: state.phase == RecognitionPhase.capturing
                        ? controller.cancel
                        : null,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  )
                : FilledButton.icon(
                    onPressed: controller.recognize,
                    icon: const Icon(Icons.graphic_eq),
                    label: const Text('Identify song'),
                  ),
          ],
        ),
      ),
    );
  }

  static (String, String?, Color?) _describe(RecognitionState state) {
    final seconds = state.elapsed == null
        ? null
        : (state.elapsed!.inMilliseconds / 1000).toStringAsFixed(1);

    return switch (state.phase) {
      RecognitionPhase.idle => (
        'Hear something you like?',
        'Sonora listens for about 10 seconds. Only an audio fingerprint is sent to ACRCloud.',
        null,
      ),
      RecognitionPhase.requestingPermission => (
        'Checking microphone access…',
        null,
        null,
      ),
      RecognitionPhase.capturing => (
        'Listening…',
        'Hold your phone towards the music.',
        AppColors.accent,
      ),
      RecognitionPhase.matching => ('Matching…', null, AppColors.accent),
      RecognitionPhase.matched => (
        'Found it',
        'Took $seconds s.',
        AppColors.success,
      ),
      RecognitionPhase.noMatch => (
        'No match',
        'Try again closer to the speaker, or when the music is louder.',
        AppColors.warning,
      ),
      RecognitionPhase.failed => (
        _errorTitle(state.errorCode),
        _errorDetail(state.errorCode),
        AppColors.error,
      ),
    };
  }

  static String _errorTitle(String? code) => switch (code) {
    'CANCELLED' => 'Cancelled',
    RecognitionErrors.permissionDenied ||
    RecognitionErrors.permissionPermanentlyDenied => 'Microphone access needed',
    _ => "Couldn't identify the song",
  };

  static String? _errorDetail(String? code) => switch (code) {
    'CANCELLED' => null,
    RecognitionErrors.permissionDenied => 'Sonora needs the microphone to hear the music. Nothing is recorded or stored.',
    RecognitionErrors.permissionPermanentlyDenied =>
      'Enable it in Settings › Apps › Sonora › Permissions › Microphone.',
    'MICROPHONE_SILENT' => 'The microphone returned silence. Check that microphone access is on in Quick Settings.',
    'MICROPHONE_UNAVAILABLE' => 'The microphone is busy or unavailable. Close any app using it and try again.',
    'NETWORK_UNAVAILABLE' => "Couldn't reach ACRCloud. Check your connection.",
    'INVALID_CREDENTIALS' =>
      'ACRCloud rejected the credentials. Check android/local.properties.',
    'NOT_CONFIGURED' =>
      'ACRCloud credentials are missing from android/local.properties.',
    'PROVIDER_UNAVAILABLE' => 'This build has no recognition engine. See docs/RECOGNITION_FEASIBILITY.md.',
    'QUOTA_EXCEEDED' => 'ACRCloud request limit reached. Try again later.',
    'BUSY' => 'A recognition is already running.',
    final other => 'Error code: ${other ?? 'unknown'}',
  };
}
