import 'package:material_ui/material_ui.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const DashboardScreen(),
    );
  }
}
