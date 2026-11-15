import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

class SonoraApp extends ConsumerWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sonora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const AppGate(),
    );
  }
}
