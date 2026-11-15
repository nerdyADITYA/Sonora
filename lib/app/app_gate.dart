import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/onboarding/providers/privacy_consent_controller.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../shared/widgets/pop.dart';
import 'home_shell.dart';

/// Shows onboarding (welcome, privacy disclosure, permissions) until the
/// user has agreed to the disclosure or chosen to skip it, then the app.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  /// Decided once, from the first answer, so agreeing mid-onboarding still
  /// leads on to the permissions page.
  bool? _onboarding;

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(privacyConsentProvider);
    _onboarding ??= switch (consent) {
      AsyncData(:final value) => !value,
      // Without an answer from the bridge, the native checks still guard the microphone.
      AsyncError() => false,
      _ => null,
    };

    return switch (_onboarding) {
      null => const Scaffold(body: Center(child: WaveformLogo(size: 72))),
      true => OnboardingScreen(
        onDone: () => setState(() => _onboarding = false),
      ),
      false => const HomeShell(),
    };
  }
}
