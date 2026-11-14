import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/core/models/history.dart';
import 'package:sonora/core/models/recognized_song.dart';
import 'package:sonora/core/models/spotify.dart';

import '../support/fake_platform.dart';
import '../support/pump.dart';

FakePlatform _withSong({bool connected = true}) {
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
          spotifyTrackId: 'T1',
          recognizedAt: DateTime.now(),
        ),
      ),
    );
  if (connected) {
    platform.spotify = const SpotifyStatus(
      configured: true,
      connected: true,
      displayName: 'Aditya',
    );
  }
  return platform;
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _openSongDetail(WidgetTester tester) async {
  await _openTab(tester, 'History');
  await tester.tap(find.text('Snowman'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connecting opens Spotify and shows the account once signed in', (
    tester,
  ) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);
    await _openTab(tester, 'Settings');

    await tester.tap(find.text('Connect Spotify'));
    // The waiting spinner animates until the browser returns, so don't settle.
    await tester.pump(const Duration(milliseconds: 100));
    expect(platform.connectCalls, 1);
    expect(find.text('Waiting for Spotify…'), findsOneWidget);

    platform.completeSpotifySignIn('Aditya');
    await tester.pumpAndSettle();
    expect(find.text('Connected as Aditya'), findsOneWidget);
    expect(find.text('Ask each time'), findsOneWidget);
  });

  testWidgets('a sign-in error is explained', (tester) async {
    final platform = FakePlatform();
    await pumpSonora(tester, platform);
    await _openTab(tester, 'Settings');

    platform.emit('spotify_status', {
      'configured': true,
      'connected': false,
      'error': 'SPOTIFY_AUTH_CANCELLED',
    });
    await tester.pumpAndSettle();

    expect(find.text('Spotify sign-in was cancelled.'), findsOneWidget);
  });

  testWidgets('without a connection, Add to playlist points to Settings', (
    tester,
  ) async {
    await pumpSonora(tester, _withSong(connected: false));
    await _openSongDetail(tester);

    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connect Spotify in Settings'), findsOneWidget);
  });

  testWidgets(
    'first add asks for a playlist, remembers it, and never adds twice',
    (tester) async {
      final platform = _withSong();
      await pumpSonora(tester, platform);
      await _openSongDetail(tester);

      await tester.tap(find.text('Add to playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a playlist'), findsOneWidget);

      await tester.tap(find.text('Road trip'));
      await tester.pumpAndSettle();
      expect(find.text('Added to Road trip'), findsOneWidget);
      expect(platform.spotify.defaultPlaylist?.id, 'p1');
      expect(find.text('✓ In Road trip'), findsOneWidget);

      // Second tap goes straight to the remembered playlist.
      await tester.tap(find.text('Add to playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a playlist'), findsNothing);
      expect(find.text('Already in Road trip'), findsOneWidget);
      expect(platform.added, {(7, 'p1')});
    },
  );

  testWidgets('a search match must be confirmed before adding', (tester) async {
    final platform = _withSong()
      ..spotify = const SpotifyStatus(
        configured: true,
        connected: true,
        defaultPlaylist: SpotifyPlaylistRef(id: 'p1', name: 'Road trip'),
      )
      ..match = const SpotifyTrackMatch(
        trackId: 'S9',
        title: 'Snowman',
        artist: 'Sia',
        album: 'Everyday Is Christmas',
        confirmed: false,
      );
    await pumpSonora(tester, platform);
    await _openSongDetail(tester);

    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Is this the right song?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(platform.added, isEmpty);

    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, add it'));
    await tester.pumpAndSettle();
    expect(platform.added, {(7, 'p1')});
  });

  testWidgets('creating a new playlist from the picker', (tester) async {
    final platform = _withSong();
    await pumpSonora(tester, platform);
    await _openSongDetail(tester);

    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('New playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Added to Sonora discoveries'), findsOneWidget);
    expect(platform.added, {(7, 'new')});
  });

  testWidgets('the picker explains playlists owned by another account', (
    tester,
  ) async {
    final platform = _withSong()..hiddenPlaylists = 7;
    await pumpSonora(tester, platform);
    await _openSongDetail(tester);

    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7 more playlists are hidden'), findsOneWidget);
  });
}
