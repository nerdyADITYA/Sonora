import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sonora/app/sonora_app.dart';
import 'package:sonora/core/errors/platform_failure.dart';
import 'package:sonora/core/models/listening_status.dart';
import 'package:sonora/core/models/platform_info.dart';
import 'package:sonora/core/models/sonora_event.dart';
import 'package:sonora/core/platform/sonora_platform.dart';

class _FakePlatform extends SonoraPlatform {
  _FakePlatform({this.fail = false});

  final bool fail;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    if (fail) throw const PlatformFailure.unavailable();
    return const PlatformInfo(
      manufacturer: 'samsung',
      brand: 'samsung',
      model: 'SM-S928B',
      device: 'e3q',
      androidVersion: '17',
      sdkInt: 37,
      securityPatch: '2026-11-01',
      isSamsung: true,
      appVersion: '0.1.0',
    );
  }

  @override
  Future<ListeningStatus> getListeningStatus() async =>
      const ListeningStatus(listening: false, available: false);

  @override
  Stream<SonoraEvent> get events => Stream.value(
    SonoraEvent(type: 'bridge_connected', timestamp: DateTime(2026)),
  );
}

Widget _app(SonoraPlatform platform) => ProviderScope(
  retry: (_, _) => null,
  overrides: [sonoraPlatformProvider.overrideWithValue(platform)],
  child: const SonoraApp(),
);

void main() {
  testWidgets('dashboard shows bridge data and an honest listening state', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakePlatform()));
    await tester.pumpAndSettle();

    expect(find.text('Sonora'), findsWidgets);
    expect(find.text('Not listening'), findsOneWidget);
    expect(find.text('No songs yet'), findsOneWidget);
    expect(find.text('samsung SM-S928B'), findsOneWidget);
    expect(find.text('17 (API 37)'), findsOneWidget);
    expect(find.text('Event channel: Connected'), findsOneWidget);

    // Listening cannot be toggled until the native service exists.
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.onChanged, isNull);
  });

  testWidgets(
    'dashboard shows the failure code when the bridge is unavailable',
    (tester) async {
      await tester.pumpWidget(_app(_FakePlatform(fail: true)));
      await tester.pumpAndSettle();

      expect(find.text(PlatformFailure.bridgeUnavailable), findsOneWidget);
    },
  );
}
