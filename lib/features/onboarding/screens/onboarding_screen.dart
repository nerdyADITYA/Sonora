import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/recognized_song.dart';
import '../../../core/platform/sonora_platform.dart';
import '../../../shared/widgets/pop.dart';
import '../providers/privacy_consent_controller.dart';
import '../widgets/privacy_disclosure.dart';

/// First launch: a welcome, the prominent privacy disclosure, then the
/// Android permissions, in that order. Android's microphone prompt only
/// appears after the user has agreed to the disclosure.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user finishes, or skips the disclosure.
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _step = 0;

  void _next() => setState(() => _step++);

  Future<void> _agree() async {
    await ref.read(privacyConsentProvider.notifier).accept();
    _next();
  }

  Future<void> _skip() async {
    final skip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip for now?'),
        content: const Text(
          "Sonora can't identify songs without the microphone. You can look "
          'around and agree later from Home or Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (skip == true) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            0 => _Welcome(key: const ValueKey(0), onNext: _next),
            1 => _Disclosure(
              key: const ValueKey(1),
              onAgree: _agree,
              onSkip: _skip,
            ),
            _ => _Permissions(key: const ValueKey(2), onDone: widget.onDone),
          },
        ),
      ),
    );
  }
}

/// A page with scrolling content and buttons pinned to the bottom.
class _Page extends StatelessWidget {
  const _Page({
    required this.step,
    required this.children,
    required this.buttons,
  });

  final int step;
  final List<Widget> children;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: i == step ? 28 : 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: ShapeDecoration(
                    color: i == step ? p.accent : p.surfaceHigh,
                    shape: StadiumBorder(
                      side: BorderSide(color: p.ink, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            children: children,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          ),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return _Page(
      step: 0,
      buttons: [
        SizedBox(
          height: 58,
          child: FilledButton(onPressed: onNext, child: const Text("Let's go")),
        ),
      ],
      children: [
        const SizedBox(height: 24),
        Center(
          child: PopCard(
            color: p.surface,
            padding: const EdgeInsets.all(28),
            radius: 36,
            shadowOffset: 6,
            child: const WaveformLogo(size: 96),
          ),
        ),
        const SizedBox(height: 40),
        Text('hey, i’m\nsonora ✦', style: theme.textTheme.displaySmall),
        const SizedBox(height: 16),
        Text(
          'I find out what song is playing, when you ask, or in the '
          'background when you let me. Then I keep a board of everything '
          "you've heard and can add it to Spotify.",
          style: theme.textTheme.bodyLarge?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PopChip('identify songs', color: p.pink),
            PopChip('ambient listening', color: p.violet),
            PopChip('your history', color: p.teal),
            PopChip('spotify playlists', color: p.yellow),
          ],
        ),
      ],
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({super.key, required this.onAgree, required this.onSkip});

  final Future<void> Function() onAgree;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Page(
      step: 1,
      buttons: [
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: onAgree,
            child: const Text('Agree and continue'),
          ),
        ),
        TextButton(onPressed: onSkip, child: const Text('Not now')),
      ],
      children: [
        Text('before we\nstart', style: theme.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'Here is how Sonora uses your microphone and data.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        const PopCard(child: PrivacyDisclosure()),
      ],
    );
  }
}

class _Permissions extends ConsumerStatefulWidget {
  const _Permissions({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends ConsumerState<_Permissions> {
  MicrophonePermission? _result;
  var _asking = false;

  Future<void> _ask() async {
    setState(() => _asking = true);
    MicrophonePermission result;
    try {
      result = await ref
          .read(sonoraPlatformProvider)
          .requestMicrophonePermission();
    } on PlatformFailure {
      result = MicrophonePermission.denied;
    }
    if (!mounted) return;
    setState(() {
      _asking = false;
      _result = result;
    });
    if (result == MicrophonePermission.granted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    final result = _result;

    return _Page(
      step: 2,
      buttons: [
        if (result == MicrophonePermission.permanentlyDenied)
          SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: () =>
                  ref.read(sonoraPlatformProvider).openBatterySettings(),
              child: const Text('Open app settings'),
            ),
          )
        else
          SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: _asking ? null : _ask,
              child: Text(result == null ? 'Allow access' : 'Try again'),
            ),
          ),
        TextButton(
          onPressed: widget.onDone,
          child: Text(result == null ? 'Later' : 'Continue without it'),
        ),
      ],
      children: [
        Text('two quick\npermissions', style: theme.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'Android will ask you next. You can change these at any time in '
          'Android settings.',
          style: theme.textTheme.bodyLarge?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 20),
        PopCard(
          child: Column(
            children: [
              _PermissionRow(
                icon: Icons.mic_none,
                color: p.pink,
                title: 'Microphone',
                body: 'Needed to hear the music you want to identify.',
              ),
              const SizedBox(height: 18),
              _PermissionRow(
                icon: Icons.notifications_none,
                color: p.violet,
                title: 'Notifications',
                body:
                    'Shows when ambient listening is on, with a Stop button, '
                    'and the songs it finds.',
              ),
            ],
          ),
        ),
        if (result != null && result != MicrophonePermission.granted) ...[
          const SizedBox(height: 16),
          Text(
            result == MicrophonePermission.permanentlyDenied
                ? 'Microphone access is turned off. Turn it on in Sonora’s '
                      'app settings under Permissions.'
                : 'Without the microphone, Sonora can’t identify songs.',
            style: theme.textTheme.bodyMedium?.copyWith(color: p.warning),
          ),
        ],
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context);
    return Row(
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
              const SizedBox(height: 2),
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
    );
  }
}
