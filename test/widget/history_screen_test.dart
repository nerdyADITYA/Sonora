import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sonora/core/models/history.dart';
import 'package:sonora/core/models/recognized_song.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

HistoryEntry _entry(
  int eventId,
  int songId,
  String title,
  String artist,
  DateTime at, {
  RecognitionSource source = RecognitionSource.ambient,
}) => HistoryEntry(
  eventId: eventId,
  songId: songId,
  source: source,
  song: RecognizedSong(
    provider: 'acrcloud',
    providerId: 'id$songId',
    title: title,
    artist: artist,
    album: 'Album $songId',
    durationMs: 205000,
    recognizedAt: at,
  ),
);

FakePlatform _withHistory() {
  final now = DateTime.now();
  return FakePlatform()
    ..history.addAll([
      _entry(3, 2, 'Chandelier', 'Sia', now),
      _entry(2, 1, 'Snowman', 'Sia', now.subtract(const Duration(days: 1))),
      _entry(
        1,
        1,
        'Snowman',
        'Sia',
        now.subtract(const Duration(days: 2)),
        source: RecognitionSource.manual,
      ),
    ]);
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.text('History').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty history explains how songs get there', (tester) async {
    await pumpSonora(tester, FakePlatform());
    await _openHistory(tester);

    expect(find.text('No songs yet'), findsOneWidget);
    expect(
      find.textContaining('saved here, on your phone only'),
      findsOneWidget,
    );
  });

  testWidgets('lists recognitions grouped by day', (tester) async {
    await pumpSonora(tester, _withHistory());
    await _openHistory(tester);

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('Chandelier'), findsOneWidget);
    expect(find.text('Snowman'), findsNWidgets(2));
  });

  testWidgets('search filters and reports no matches', (tester) async {
    await pumpSonora(tester, _withHistory());
    await _openHistory(tester);

    await tester.enterText(find.byType(SearchBar), 'chand');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Chandelier'), findsOneWidget);
    expect(find.text('Snowman'), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('swiping an entry deletes it', (tester) async {
    final platform = _withHistory();
    await pumpSonora(tester, platform);
    await _openHistory(tester);

    await tester.drag(find.text('Chandelier'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(platform.history.any((e) => e.song.title == 'Chandelier'), isFalse);
    expect(find.textContaining('Removed'), findsOneWidget);
  });

  testWidgets('clear history asks for confirmation', (tester) async {
    final platform = _withHistory();
    await pumpSonora(tester, platform);
    await _openHistory(tester);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear history?'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(platform.history, isEmpty);
    expect(find.text('No songs yet'), findsOneWidget);
  });

  testWidgets('song detail shows times heard and deletes the song', (
    tester,
  ) async {
    final platform = _withHistory();
    await pumpSonora(tester, platform);
    await _openHistory(tester);

    await tester.tap(find.text('Snowman').first);
    await tester.pumpAndSettle();

    expect(find.text('Times heard'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3:25'), findsOneWidget);
    expect(find.text('Ambient listening'), findsOneWidget);
    expect(find.text('Identified manually'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete song'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(platform.history.any((e) => e.songId == 1), isFalse);
    expect(find.text('Times heard'), findsNothing);
  });
}
