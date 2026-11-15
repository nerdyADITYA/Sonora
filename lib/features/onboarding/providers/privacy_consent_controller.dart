import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/sonora_platform.dart';

/// Where the full privacy policy is published.
final privacyPolicyUrl = Uri.parse(
  'https://github.com/nerdyADITYA/Sonora/blob/main/docs/PRIVACY.md',
);

/// Whether the user agreed to the microphone and data disclosure. Stored
/// natively, because the Quick Settings tile and the service check it too.
final privacyConsentProvider =
    AsyncNotifierProvider<PrivacyConsentController, bool>(
      PrivacyConsentController.new,
    );

class PrivacyConsentController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(sonoraPlatformProvider).getPrivacyConsent();

  Future<void> accept() async {
    state = AsyncData(
      await ref.read(sonoraPlatformProvider).setPrivacyConsent(true),
    );
  }

  /// Also stops ambient listening and any recognition in progress.
  Future<void> withdraw() async {
    state = AsyncData(
      await ref.read(sonoraPlatformProvider).setPrivacyConsent(false),
    );
  }
}
