import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/channel_names.dart';
import '../../../core/models/platform_info.dart';
import '../../../core/platform/sonora_platform.dart';

final platformInfoProvider = FutureProvider<PlatformInfo>(
  (ref) => ref.watch(sonoraPlatformProvider).getPlatformInfo(),
);

/// True once the native side has sent `bridge_connected` over the events channel.
final bridgeConnectedProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(sonoraPlatformProvider)
      .events
      .where((event) => event.type == BridgeEventTypes.bridgeConnected)
      .map((_) => true),
);
