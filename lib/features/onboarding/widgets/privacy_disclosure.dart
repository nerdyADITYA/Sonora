import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../shared/widgets/pop.dart';
import '../providers/privacy_consent_controller.dart';

/// Opens the full privacy policy in the browser.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final opened = await launchUrl(
    privacyPolicyUrl,
    mode: LaunchMode.externalApplication,
  ).catchError((Object _) => false);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Couldn't open a browser.")));
  }
}

/// The prominent disclosure: what Sonora collects, why, and who receives it.
///
/// Shown in full before Android's microphone prompt, and agreed to with an
/// explicit tap, as Google Play's User Data policy requires.
class PrivacyDisclosure extends StatelessWidget {
  const PrivacyDisclosure({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Point(
          icon: Icons.mic_none,
          color: p.pink,
          title: 'Sonora uses your microphone',
          body:
              'It records short samples of sound around you, about 10 to 12 '
              'seconds each, to identify the music playing. This happens when '
              'you tap Identify song and, if you turn on ambient listening, '
              'in the background, even when the app is closed. A notification '
              'is always shown while listening is on, and you can turn it '
              'off at any time.',
        ),
        _Point(
          icon: Icons.cloud_outlined,
          color: p.violet,
          title: 'Only a fingerprint leaves your phone',
          body:
              'Each sample is turned into an audio fingerprint on your phone '
              'and sent to ACRCloud, which identifies the song. The recording '
              'itself is only kept in memory for a moment, and is never saved '
              'or uploaded. To show a cover, the song found (its title and '
              'artist, or Spotify ID) is looked up on Spotify or Apple iTunes.',
        ),
        _Point(
          icon: Icons.phone_android,
          color: p.teal,
          title: 'Your history stays on this phone',
          body:
              'The songs Sonora finds are saved only on this phone. You can '
              'delete them at any time in History.',
        ),
        _Point(
          icon: Icons.queue_music,
          color: p.accent,
          title: 'Spotify, only if you connect it',
          body:
              'If you connect Spotify, song titles and artists are sent to '
              'Spotify to find tracks and add them to your playlists.',
        ),
        _Point(
          icon: Icons.block,
          color: p.yellow,
          title: 'No ads, no analytics, no account',
          body:
              'Sonora has no tracking and no Sonora account. Nothing is sold.',
          last: true,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openPrivacyPolicy(context),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Read the full privacy policy'),
          ),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              color: color,
              shape: CircleBorder(side: BorderSide(color: p.ink, width: 2)),
            ),
            child: Icon(icon, color: p.onPop, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The disclosure as its own page, for agreeing later (from Home or
/// Settings) after skipping it during setup. Pops with true once agreed.
class PrivacyDisclosureScreen extends ConsumerWidget {
  const PrivacyDisclosureScreen({super.key});

  static Future<bool> open(BuildContext context) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PrivacyDisclosureScreen()),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('before you\nstart', style: theme.textTheme.displaySmall),
          const SizedBox(height: 24),
          const PopCard(child: PrivacyDisclosure()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () async {
                  await ref.read(privacyConsentProvider.notifier).accept();
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Agree and continue'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
