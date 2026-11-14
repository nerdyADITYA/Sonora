import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sonora/app/sonora_app.dart';
import 'package:sonora/core/platform/sonora_platform.dart';

/// Pumps the whole app against [platform] on a tall phone-shaped surface.
Future<void> pumpSonora(WidgetTester tester, SonoraPlatform platform) async {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [sonoraPlatformProvider.overrideWithValue(platform)],
      child: const SonoraApp(),
    ),
  );
  await tester.pumpAndSettle();
}
