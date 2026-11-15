import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark, or follow the phone. Saved on the phone and restored at launch.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = ThemeMode.values.asNameMap()[prefs.getString(_key)];
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // No storage (tests, a broken prefs file): follow the phone.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // The choice still applies until the app restarts.
    }
  }

  /// Switches to the opposite of what is on screen now.
  Future<void> toggle(Brightness current) =>
      set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
