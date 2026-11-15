import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/core/models/history.dart';
import 'package:sonora/core/models/listening_status.dart';
import 'package:sonora/core/models/recognized_song.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

void main() {
  testWidgets(
    'an interrupted session is explained, with battery settings and dismiss',
    (tester) async {
      final platform = FakePlatform()
        ..listeningStatus = const ListeningStatus(
          listening: false,
          available: true,
          interrupted: true,
          batteryUnrestricted: false,
        );
      await pumpSonora(tester, platform);

      expect(find.text('Listening was stopped'), findsOneWidget);
      expect(find.textContaining('Unrestricted'), findsOneWidget);

      await tester.tap(find.text('Battery settings'));
      expect(platform.batterySettingsOpened, 1);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Listening was stopped'), findsNothing);
      expect(find.text('Not listening'), findsOneWidget);
    },
  );

  testWidgets('with unrestricted battery only dismiss is offered', (
    tester,
  ) async {
    final platform = FakePlatform()
      ..listeningStatus = const ListeningStatus(
        listening: false,
        available: true,
        interrupted: true,
      );
    await pumpSonora(tester, platform);

    expect(find.text('Listening was stopped'), findsOneWidget);
    expect(find.text('Battery settings'), findsNothing);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('battery saver is mentioned while listening', (tester) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);

    platform.emit('listening_status', {
      'listening': true,
      'available': true,
      'phase': 'waiting',
      'requestsToday': 4,
      'dailyBudget': 200,
      'powerSave': true,
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('battery saver'), findsOneWidget);
  });

  testWidgets('settings can add the Quick Settings tile', (tester) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Quick Settings tile'));
    await tester.pumpAndSettle();

    expect(find.text('Tile added to Quick Settings.'), findsOneWidget);
  });

  testWidgets('tapping the notification opens the song', (tester) async {
    final platform = FakePlatform()
      ..history.add(
        HistoryEntry(
          eventId: 1,
          songId: 7,
          source: RecognitionSource.ambient,
          song: RecognizedSong(
            provider: 'acrcloud',
            providerId: 'a',
            title: 'Snowman',
            artist: 'Sia',
            recognizedAt: DateTime.now(),
          ),
        ),
      )
      ..launchSongId = 7;
    await pumpSonora(tester, platform);

    // The detail page shows its actions.
    expect(find.text('Add to playlist'), findsOneWidget);
    expect(platform.launchSongId, isNull);
  });
}
