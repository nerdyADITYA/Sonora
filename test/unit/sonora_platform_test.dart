import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/core/constants/channel_names.dart';
import 'package:sonora/core/errors/platform_failure.dart';
import 'package:sonora/core/models/sonora_event.dart';
import 'package:sonora/core/platform/sonora_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ChannelNames.control);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SonoraPlatform platform;

  void mockResponse(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async => handler(call));
  }

  setUp(() => platform = SonoraPlatform());
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('getPlatformInfo parses a success envelope', () async {
    mockResponse(
      (call) => {
        'success': true,
        'data': {
          'manufacturer': 'samsung',
          'brand': 'samsung',
          'model': 'SM-S928B',
          'device': 'e3q',
          'androidVersion': '17',
          'sdkInt': 37,
          'securityPatch': '2026-11-01',
          'isSamsung': true,
          'appVersion': '0.1.0',
        },
        'error': null,
      },
    );

    final info = await platform.getPlatformInfo();

    expect(info.displayName, 'samsung SM-S928B');
    expect(info.sdkInt, 37);
    expect(info.isSamsung, isTrue);
  });

  test('getListeningStatus parses listening state', () async {
    mockResponse(
      (call) => {
        'success': true,
        'data': {'listening': false, 'available': false},
        'error': null,
      },
    );

    final status = await platform.getListeningStatus();

    expect(status.listening, isFalse);
    expect(status.available, isFalse);
  });

  test('a failure envelope becomes a PlatformFailure with its code', () async {
    mockResponse(
      (call) => {
        'success': false,
        'data': null,
        'error': {'code': 'NOT_IMPLEMENTED', 'message': 'Not yet.'},
      },
    );

    expect(
      platform.getListeningStatus(),
      throwsA(
        isA<PlatformFailure>().having((f) => f.code, 'code', 'NOT_IMPLEMENTED'),
      ),
    );
  });

  test('a malformed response is reported, not crashed on', () async {
    mockResponse((call) => 'not a map');

    expect(
      platform.getPlatformInfo(),
      throwsA(
        isA<PlatformFailure>().having(
          (f) => f.code,
          'code',
          PlatformFailure.malformedResponse,
        ),
      ),
    );
  });

  test('a missing native handler maps to BRIDGE_UNAVAILABLE', () async {
    expect(
      platform.getPlatformInfo(),
      throwsA(
        isA<PlatformFailure>().having(
          (f) => f.code,
          'code',
          PlatformFailure.bridgeUnavailable,
        ),
      ),
    );
  });

  test('SonoraEvent.fromNative reads type, timestamp and data', () {
    final event = SonoraEvent.fromNative({
      'type': 'bridge_connected',
      'timestamp': 1000,
      'data': {'k': 'v'},
    });

    expect(event.type, 'bridge_connected');
    expect(event.timestamp.millisecondsSinceEpoch, 1000);
    expect(event.data, {'k': 'v'});
  });
}
