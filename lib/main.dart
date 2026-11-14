import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/sonora_app.dart';

void main() {
  runApp(
    // Bridge failures are deterministic, so automatic retries only add noise.
    // Screens offer an explicit refresh instead.
    ProviderScope(retry: (_, _) => null, child: const SonoraApp()),
  );
}
