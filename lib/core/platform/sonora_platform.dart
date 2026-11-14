import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/channel_names.dart';
import '../errors/platform_failure.dart';
import '../models/bridge_response.dart';
import '../models/listening_status.dart';
import '../models/platform_info.dart';
import '../models/sonora_event.dart';

final sonoraPlatformProvider = Provider<SonoraPlatform>(
  (ref) => SonoraPlatform(),
);

/// The only place Dart talks to the Kotlin bridge. Features use this through
/// providers, never the channels directly.
class SonoraPlatform {
  SonoraPlatform({MethodChannel? control, EventChannel? events})
    : _control = control ?? const MethodChannel(ChannelNames.control),
      _eventsChannel = events ?? const EventChannel(ChannelNames.events);

  final MethodChannel _control;
  final EventChannel _eventsChannel;
  Stream<SonoraEvent>? _events;

  Future<PlatformInfo> getPlatformInfo() async =>
      PlatformInfo.fromMap(await _invoke(BridgeMethods.getPlatformInfo));

  Future<ListeningStatus> getListeningStatus() async =>
      ListeningStatus.fromMap(await _invoke(BridgeMethods.getListeningStatus));

  /// Broadcast stream of native events; safe to listen to more than once.
  Stream<SonoraEvent> get events => _events ??= _eventsChannel
      .receiveBroadcastStream()
      .map(SonoraEvent.fromNative);

  Future<Map<String, Object?>> _invoke(
    String method, [
    Object? arguments,
  ]) async {
    final Object? raw;
    try {
      raw = await _control.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      throw const PlatformFailure.unavailable();
    } on PlatformException catch (e) {
      throw PlatformFailure(e.code, e.message ?? 'Native call failed.');
    }
    return unwrapBridgeResponse(raw);
  }
}
