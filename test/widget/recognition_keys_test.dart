import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sonora/core/models/recognition_provider.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without keys, Settings asks for an ACRCloud project', (
    tester,
  ) async {
    final platform = FakePlatform()
      ..recognitionProvider = const RecognitionProvider(
        sdkAvailable: true,
        source: KeySource.none,
      );
    await pumpSonora(tester, platform);
    await _openSettings(tester);

    expect(find.text('Set up ACRCloud'), findsOneWidget);
    expect(find.text('Enter ACRCloud keys'), findsOneWidget);
    expect(find.text('Remove keys'), findsNothing);
  });

  testWidgets('keys are saved natively and only the host is shown', (
    tester,
  ) async {
    final platform = FakePlatform()
      ..recognitionProvider = const RecognitionProvider(
        sdkAvailable: true,
        source: KeySource.none,
      );
    await pumpSonora(tester, platform);
    await _openSettings(tester);

    await tester.tap(find.text('Enter ACRCloud keys'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'identify-eu-west-1.acrcloud.com');
    await tester.enterText(fields.at(1), 'key123');
    await tester.enterText(fields.at(2), 'secret456');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(platform.savedKeys, {
      'host': 'identify-eu-west-1.acrcloud.com',
      'accessKey': 'key123',
      'accessSecret': 'secret456',
    });
    expect(find.text('Your ACRCloud project'), findsOneWidget);
    expect(find.text('identify-eu-west-1.acrcloud.com'), findsOneWidget);
    expect(find.text('secret456'), findsNothing);
    expect(find.text('Remove keys'), findsOneWidget);
  });

  testWidgets('a refused host keeps the dialog open with the reason', (
    tester,
  ) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);
    await _openSettings(tester);

    await tester.tap(find.text('Enter ACRCloud keys'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'example.com');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter the host from your ACRCloud project.'),
      findsOneWidget,
    );
    expect(platform.savedKeys, isNull);
  });

  testWidgets('a build without the SDK says so', (tester) async {
    final platform = FakePlatform()
      ..recognitionProvider = const RecognitionProvider(
        sdkAvailable: false,
        source: KeySource.none,
      );
    await pumpSonora(tester, platform);
    await _openSettings(tester);

    expect(find.text('Recognition unavailable'), findsOneWidget);
    expect(find.text('Enter ACRCloud keys'), findsNothing);
  });

  testWidgets('a fresh install is guided from Home to saved keys', (
    tester,
  ) async {
    final platform = FakePlatform()
      ..recognitionProvider = const RecognitionProvider(
        sdkAvailable: true,
        source: KeySource.none,
      );
    await pumpSonora(tester, platform);

    expect(find.text('Set up recognition first'), findsOneWidget);
    expect(find.text('Identify song'), findsNothing);

    await tester.tap(find.text('Set up ACRCloud'));
    await tester.pumpAndSettle();
    expect(find.text('Make a free account'), findsOneWidget);
    expect(find.text('Open ACRCloud console'), findsOneWidget);

    final enter = find.text('Enter ACRCloud keys');
    await tester.ensureVisible(enter);
    await tester.pumpAndSettle();
    await tester.tap(enter);
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'identify-eu-west-1.acrcloud.com');
    await tester.enterText(fields.at(1), 'key123');
    await tester.enterText(fields.at(2), 'secret456');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text("You're all set"), -200);
    await tester.tap(find.text('Start identifying'));
    await tester.pumpAndSettle();
    expect(find.text('Identify song'), findsOneWidget);
  });
}
