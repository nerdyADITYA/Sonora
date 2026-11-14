import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sonora/app/sonora_app.dart';
import 'package:sonora/core/errors/platform_failure.dart';
import 'package:sonora/core/models/listening_status.dart';
import 'package:sonora/core/models/platform_info.dart';
import 'package:sonora/core/models/recognized_song.dart';
import 'package:sonora/core/models/sonora_event.dart';
import 'package:sonora/core/platform/sonora_platform.dart';

class _FakePlatform extends SonoraPlatform {
  _FakePlatform({
    this.failInfo = false,
    this.permission = MicrophonePermission.granted,
    this.attempt,
    this.recognitionFailure,
  });

  final bool failInfo;
  final MicrophonePermission permission;
  final RecognitionAttempt? attempt;
  final PlatformFailure? recognitionFailure;

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    if (failInfo) throw const PlatformFailure.unavailable();
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

  final _events = StreamController<SonoraEvent>.broadcast();
  ListeningStatus _status = ListeningStatus.stopped;

  void emit(String type, Map<String, Object?> data) => _events.add(
    SonoraEvent(type: type, timestamp: DateTime(2026), data: data),
  );

  @override
  Future<ListeningStatus> getListeningStatus() async => _status;

  @override
  Future<ListeningStatus> startListening() async => _status = ListeningStatus(
    listening: true,
    available: true,
    phase: ListeningPhase.waiting,
    nextCheckAt: DateTime(2026, 11, 14, 18, 30),
    requestsToday: 3,
    dailyBudget: 200,
  );

  @override
  Future<void> stopListening() async => _status = ListeningStatus.stopped;

  @override
  Future<MicrophonePermission> requestMicrophonePermission() async =>
      permission;

  @override
  Future<RecognitionAttempt> recognizeOnce() async {
    if (recognitionFailure != null) throw recognitionFailure!;
    return attempt ??
        const RecognitionAttempt(song: null, elapsed: Duration(seconds: 10));
  }

  @override
  Stream<SonoraEvent> get events async* {
    yield SonoraEvent(type: 'bridge_connected', timestamp: DateTime(2026));
    yield* _events.stream;
  }
}

final _song = RecognizedSong(
  provider: 'acrcloud',
  providerId: 'abc123',
  title: 'Watermelon Sugar',
  artist: 'Harry Styles',
  album: 'Fine Line',
  confidence: 1.0,
  recognizedAt: DateTime(2026, 11, 14),
);

Future<void> _pump(WidgetTester tester, SonoraPlatform platform) async {
  // Tall surface so every dashboard card is built.
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

Future<void> _tapIdentify(WidgetTester tester) async {
  await tester.tap(find.text('Identify song'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows bridge data and an honest listening state', (
    tester,
  ) async {
    await _pump(tester, _FakePlatform());

    expect(find.text('Sonora'), findsWidgets);
    expect(find.text('Not listening'), findsOneWidget);
    expect(find.text('No songs yet'), findsOneWidget);
    expect(find.text('samsung SM-S928B'), findsOneWidget);
    expect(find.text('17 (API 37)'), findsOneWidget);
    expect(find.text('Event channel: Connected'), findsOneWidget);

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNotNull);
  });

  testWidgets(
    'dashboard shows the failure code when the bridge is unavailable',
    (tester) async {
      await _pump(tester, _FakePlatform(failInfo: true));

      expect(find.text(PlatformFailure.bridgeUnavailable), findsOneWidget);
    },
  );

  testWidgets('identifying a song shows it as the last discovery', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePlatform(
        attempt: RecognitionAttempt(
          song: _song,
          elapsed: const Duration(milliseconds: 11200),
        ),
      ),
    );

    await _tapIdentify(tester);

    expect(find.text('Found it'), findsOneWidget);
    expect(find.text('Took 11.2 s.'), findsOneWidget);
    expect(find.text('Watermelon Sugar'), findsOneWidget);
    expect(find.text('Harry Styles'), findsOneWidget);
    expect(find.text('No songs yet'), findsNothing);
  });

  testWidgets('a no-match keeps the empty state and suggests retrying', (
    tester,
  ) async {
    await _pump(tester, _FakePlatform());

    await _tapIdentify(tester);

    expect(find.text('No match'), findsOneWidget);
    expect(find.text('No songs yet'), findsOneWidget);
  });

  testWidgets('a permanently denied microphone points to Settings', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePlatform(permission: MicrophonePermission.permanentlyDenied),
    );

    await _tapIdentify(tester);

    expect(find.text('Microphone access needed'), findsOneWidget);
    expect(find.textContaining('Settings › Apps › Sonora'), findsOneWidget);
  });

  testWidgets('provider errors are explained from their code', (tester) async {
    await _pump(
      tester,
      _FakePlatform(
        recognitionFailure: const PlatformFailure(
          'NETWORK_UNAVAILABLE',
          'status 3000',
        ),
      ),
    );

    await _tapIdentify(tester);

    expect(find.text("Couldn't identify the song"), findsOneWidget);
    expect(find.textContaining("Couldn't reach ACRCloud"), findsOneWidget);
  });

  testWidgets('turning listening on shows live status and pauses Identify', (
    tester,
  ) async {
    await _pump(tester, _FakePlatform());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Listening for music'), findsOneWidget);
    expect(find.textContaining('3/200 checks today'), findsOneWidget);
    expect(find.text('Listening automatically'), findsOneWidget);
    final identify = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(identify.onPressed, isNull);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Not listening'), findsOneWidget);
  });

  testWidgets('a denied microphone keeps listening off and explains why', (
    tester,
  ) async {
    await _pump(tester, _FakePlatform(permission: MicrophonePermission.denied));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Not listening'), findsOneWidget);
    expect(find.textContaining('needs the microphone'), findsOneWidget);
  });

  testWidgets('songs found by ambient listening become the last discovery', (
    tester,
  ) async {
    final platform = _FakePlatform();
    await _pump(tester, platform);

    platform.emit('song_recognized', {
      'provider': 'acrcloud',
      'providerId': 'xyz',
      'title': 'Snowman',
      'artist': 'Sia',
      'album': 'Everyday Is Christmas',
      'recognizedAt': 1000,
    });
    await tester.pumpAndSettle();

    expect(find.text('Snowman'), findsOneWidget);
    expect(find.text('Sia'), findsOneWidget);
  });

  testWidgets('a background status event updates the listening card', (
    tester,
  ) async {
    final platform = _FakePlatform();
    await _pump(tester, platform);

    platform.emit('listening_status', {
      'listening': true,
      'available': true,
      'phase': 'paused_budget',
      'requestsToday': 200,
      'dailyBudget': 200,
    });
    await tester.pumpAndSettle();

    expect(find.text('Paused for today'), findsOneWidget);
  });
}
