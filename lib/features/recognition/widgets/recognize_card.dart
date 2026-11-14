import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../listening/providers/listening_controller.dart';
import '../providers/recognition_controller.dart';
import '../recognition_error_copy.dart';

/// Manual "identify this song" control with status and error copy.
class RecognizeCard extends ConsumerWidget {
  const RecognizeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(recognitionControllerProvider);
    final controller = ref.read(recognitionControllerProvider.notifier);
    final listening = ref.watch(
      listeningControllerProvider.select((s) => s.listening),
    );
    var (headline, detail, color) = _describe(state);
    if (listening && !state.isBusy) {
      (headline, detail, color) = (
        'Listening automatically',
        'Ambient listening is on, so songs appear below as they are found.',
        null,
      );
    }

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
                    onPressed: listening ? null : controller.recognize,
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

  static String? _errorDetail(String? code) => recognitionErrorDetail(code);
}
