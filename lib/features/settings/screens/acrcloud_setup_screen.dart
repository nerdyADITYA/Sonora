import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../shared/widgets/pop.dart';
import '../providers/recognition_provider_controller.dart';
import '../widgets/recognition_settings_card.dart';

/// Step-by-step help for getting free ACRCloud keys, so anyone who installs
/// the APK can set up recognition without leaving the app for long.
class AcrCloudSetupScreen extends ConsumerWidget {
  const AcrCloudSetupScreen({super.key});

  static final consoleUrl = Uri.parse('https://console.acrcloud.com/');

  Future<void> _openConsole(BuildContext context) async {
    final opened = await launchUrl(
      consoleUrl,
      mode: LaunchMode.externalApplication,
    ).catchError((Object _) => false);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open a browser. Go to console.acrcloud.com"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final theme = Theme.of(context);
    final provider = ref.watch(recognitionProviderProvider).value;
    final done = provider?.configured ?? false;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'set up\nrecognition',
              style: theme.textTheme.displaySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
            child: Text(
              'Sonora identifies songs with ACRCloud. Each person uses their '
              'own free ACRCloud project, so nobody shares keys or limits. '
              'It takes about five minutes.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: p.textSecondary,
              ),
            ),
          ),
          if (done) ...[
            PopCard(
              color: p.accent,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: p.onPop, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You're all set",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: p.onPop,
                          ),
                        ),
                        Text(
                          provider?.host ?? 'Keys saved on this phone.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: p.onPop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start identifying'),
            ),
            const SizedBox(height: 28),
          ],
          _Step(
            number: 1,
            color: p.pink,
            title: 'Make a free account',
            body:
                'Sign up at the ACRCloud console. A free trial is enough to '
                'start; ACRCloud shows its limits and pricing there.',
            action: OutlinedButton.icon(
              onPressed: () => _openConsole(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open ACRCloud console'),
            ),
          ),
          _Step(
            number: 2,
            color: p.violet,
            title: 'Create a project',
            body:
                'Open Audio & Video Recognition › Projects and create a '
                'project with these settings:',
            extra: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PopChip('Audio source: Recorded Audio', color: p.yellow),
                PopChip('Engine: Audio Fingerprinting', color: p.yellow),
                PopChip('Bucket: ACRCloud Music', color: p.yellow),
                PopChip('3rd-party IDs: Spotify, ISRC', color: p.yellow),
              ],
            ),
            footnote:
                'The Spotify ID lets Sonora add songs to your playlists '
                'and open them in Spotify.',
          ),
          _Step(
            number: 3,
            color: p.teal,
            title: 'Copy your keys',
            body:
                "Open the project's page. Copy its Host, Access Key and "
                'Access Secret.',
            extra: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                PopChip('Host', icon: Icons.dns_outlined),
                PopChip('Access Key', icon: Icons.key_outlined),
                PopChip('Access Secret', icon: Icons.lock_outline),
              ],
            ),
          ),
          _Step(
            number: 4,
            color: p.orange,
            title: 'Paste them into Sonora',
            body:
                'They are stored encrypted on this phone, never shown again, '
                'and only sent to ACRCloud.',
            action: FilledButton.icon(
              onPressed: () => showAcrCloudKeysDialog(context),
              icon: const Icon(Icons.key_outlined),
              label: Text(
                done ? 'Change ACRCloud keys' : 'Enter ACRCloud keys',
              ),
            ),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.color,
    required this.title,
    required this.body,
    this.extra,
    this.footnote,
    this.action,
    this.last = false,
  });

  final int number;
  final Color color;
  final String title;
  final String body;
  final Widget? extra;
  final String? footnote;
  final Widget? action;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: PopCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: color,
                    shape: CircleBorder(
                      side: BorderSide(color: p.ink, width: 2),
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: p.onPop,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: theme.textTheme.bodyMedium),
            if (extra != null) ...[const SizedBox(height: 12), extra!],
            if (footnote != null) ...[
              const SizedBox(height: 10),
              Text(
                footnote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}
