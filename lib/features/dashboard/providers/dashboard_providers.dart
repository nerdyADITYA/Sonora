import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/platform_info.dart';
import '../../../core/platform/sonora_platform.dart';

final platformInfoProvider = FutureProvider<PlatformInfo>(
  (ref) => ref.watch(sonoraPlatformProvider).getPlatformInfo(),
);
