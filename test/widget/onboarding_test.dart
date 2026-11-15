import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/core/models/recognized_song.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

FakePlatform _freshInstall() => FakePlatform()..privacyAccepted = false;

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows the disclosure before asking permission', (
    tester,
  ) async {
    final platform = _freshInstall();
    await pumpSonora(tester, platform);

    expect(find.text("Let's go"), findsOneWidget);
    expect(find.text('Identify song'), findsNothing);

    await _tap(tester, "Let's go");
    expect(find.text('Sonora uses your microphone'), findsOneWidget);
    expect(find.text('Only a fingerprint leaves your phone'), findsOneWidget);
    expect(find.text('Read the full privacy policy'), findsOneWidget);
    expect(platform.privacyAccepted, isFalse);

    await _tap(tester, 'Agree and continue');
    expect(platform.privacyAccepted, isTrue);
    expect(find.text('Allow access'), findsOneWidget);

    await _tap(tester, 'Allow access');
    expect(find.text('Identify song'), findsOneWidget);
  });

  testWidgets('a denied microphone can be skipped', (tester) async {
    final platform = FakePlatform(
      permission: MicrophonePermission.permanentlyDenied,
    )..privacyAccepted = false;
    await pumpSonora(tester, platform);
    await _tap(tester, "Let's go");
    await _tap(tester, 'Agree and continue');
    await _tap(tester, 'Allow access');

    expect(find.text('Open app settings'), findsOneWidget);
    await _tap(tester, 'Continue without it');
    expect(find.text('Not listening'), findsOneWidget);
  });

  testWidgets('skipping the disclosure keeps the microphone off', (
    tester,
  ) async {
    final platform = _freshInstall();
    await pumpSonora(tester, platform);
    await _tap(tester, "Let's go");
    await _tap(tester, 'Not now');
    await _tap(tester, 'Skip');

    expect(platform.privacyAccepted, isFalse);
    expect(find.text('Agree to start identifying'), findsOneWidget);
    expect(find.text('Identify song'), findsNothing);

    // Agreeing later, from Home.
    await _tap(tester, 'Review and agree');
    await _tap(tester, 'Agree and continue');
    expect(platform.privacyAccepted, isTrue);
    expect(find.text('Identify song'), findsOneWidget);
  });

  testWidgets('consent can be withdrawn in Settings', (tester) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);
    expect(find.text("Let's go"), findsNothing);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final withdraw = find.text('Withdraw microphone consent');
    await tester.scrollUntilVisible(withdraw, 200);
    await tester.pumpAndSettle();
    await tester.tap(withdraw);
    await tester.pumpAndSettle();
    await _tap(tester, 'Withdraw');

    expect(platform.privacyAccepted, isFalse);
    expect(find.text('Review and agree'), findsOneWidget);
  });
}
