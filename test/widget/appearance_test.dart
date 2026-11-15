import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.text('Not listening'))).brightness;

void main() {
  testWidgets('theme can be switched from Settings and from Home', (
    tester,
  ) async {
    await pumpSonora(tester, FakePlatform());

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
  });
}
