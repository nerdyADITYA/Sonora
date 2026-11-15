import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../shared/widgets/pop.dart';
import '../../listening/providers/listening_controller.dart';
import '../../onboarding/providers/privacy_consent_controller.dart';
import '../../onboarding/widgets/privacy_disclosure.dart';
import '../../settings/providers/recognition_provider_controller.dart';
import '../../settings/screens/acrcloud_setup_screen.dart';
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
    final p = context.palette;
    final provider = ref.watch(recognitionProviderProvider).value;
    // A fresh install has no keys: send people to the setup guide first.
    final needsKeys =
        provider != null && provider.sdkAvailable && !provider.configured;
    final needsConsent = ref.watch(privacyConsentProvider).value == false;
    var (headline, detail, color) = _describe(state, p);
    if (needsConsent && !state.isBusy) {
      (headline, detail, color) = (
        'Agree to start identifying',
        'Sonora needs your OK before it uses the microphone. See exactly '
            'what it does first.',
        null,
      );
    } else if (needsKeys && !state.isBusy) {
      (headline, detail, color) = (
        'Set up recognition first',
        'Sonora needs your own free ACRCloud keys to identify songs. '
            'It takes about five minutes.',
        null,
      );
    }
    if (listening && !state.isBusy) {
      (headline, detail, color) = (
        'Listening automatically',
        'Ambient listening is on, so songs appear below as they are found.',
        null,
      );
    }

    return PopCard(
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PopChip('identify', color: p.pink, icon: Icons.bolt),
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p.textSecondary,
              ),
            ),
          ],
          if (state.isBusy) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 8),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 58,
            child: state.isBusy
                ? OutlinedButton.icon(
                    onPressed: state.phase == RecognitionPhase.capturing
                        ? controller.cancel
                        : null,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  )
                : needsConsent
                ? FilledButton.icon(
                    onPressed: () => PrivacyDisclosureScreen.open(context),
                    icon: const Icon(Icons.privacy_tip_outlined, size: 24),
                    label: const Text('Review and agree'),
                    style: FilledButton.styleFrom(
                      textStyle: theme.textTheme.titleMedium,
                    ),
                  )
                : needsKeys
                ? FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AcrCloudSetupScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.key_outlined, size: 24),
                    label: const Text('Set up ACRCloud'),
                    style: FilledButton.styleFrom(
                      textStyle: theme.textTheme.titleMedium,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: listening ? null : controller.recognize,
                    icon: const Icon(Icons.graphic_eq, size: 24),
                    label: const Text('Identify song'),
                    style: FilledButton.styleFrom(
                      textStyle: theme.textTheme.titleMedium,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static (String, String?, Color?) _describe(
    RecognitionState state,
    SonoraPalette p,
  ) {
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
        null,
      ),
      RecognitionPhase.matching => ('Matching…', null, null),
      RecognitionPhase.matched when !state.confident => (
        'Possible match',
        'Took $seconds s. Sonora isn’t sure about this one, so check it below and delete it from History if it’s wrong.',
        p.warning,
      ),
      RecognitionPhase.matched => ('Found it', 'Took $seconds s.', p.success),
      RecognitionPhase.noMatch => (
        'No match',
        'Try again closer to the speaker, or when the music is louder.',
        p.warning,
      ),
      RecognitionPhase.failed => (
        _errorTitle(state.errorCode),
        _errorDetail(state.errorCode),
        p.error,
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
