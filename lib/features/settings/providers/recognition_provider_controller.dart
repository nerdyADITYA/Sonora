import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/recognition_provider.dart';
import '../../../core/platform/sonora_platform.dart';

/// The ACRCloud setup shown in Settings.
final recognitionProviderProvider =
    AsyncNotifierProvider<RecognitionProviderController, RecognitionProvider>(
      RecognitionProviderController.new,
    );

class RecognitionProviderController extends AsyncNotifier<RecognitionProvider> {
  @override
  Future<RecognitionProvider> build() =>
      ref.read(sonoraPlatformProvider).getRecognitionProvider();

  /// Saves the keys; rethrows the platform's message when they're refused.
  Future<void> save({
    required String host,
    required String accessKey,
    required String accessSecret,
  }) async {
    final updated = await ref
        .read(sonoraPlatformProvider)
        .setAcrCloudKeys(
          host: host,
          accessKey: accessKey,
          accessSecret: accessSecret,
        );
    state = AsyncData(updated);
  }

  Future<void> remove() async {
    state = AsyncData(
      await ref.read(sonoraPlatformProvider).clearAcrCloudKeys(),
    );
  }
}
