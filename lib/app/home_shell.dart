import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants/channel_names.dart';
import '../core/errors/platform_failure.dart';
import '../core/platform/sonora_platform.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/song_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';

/// Bottom navigation between Home, History and Settings. Tabs keep their state.
///
/// Also opens a song's page when the listening notification is tapped.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;
  StreamSubscription<Object?>? _openSong;

  @override
  void initState() {
    super.initState();
    final platform = ref.read(sonoraPlatformProvider);
    _openSong = platform.events
        .where((e) => e.type == BridgeEventTypes.openSong)
        .listen((_) => _openLaunchSong(), onError: (Object _) {});
    // A cold start from the notification: the event fired before Flutter listened.
    Future.microtask(_openLaunchSong);
  }

  @override
  void dispose() {
    _openSong?.cancel();
    super.dispose();
  }

  Future<void> _openLaunchSong() async {
    final int? songId;
    try {
      songId = await ref.read(sonoraPlatformProvider).takeLaunchSongId();
    } on PlatformFailure {
      return;
    }
    if (songId == null || !mounted) return;
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SongDetailScreen(songId: songId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DashboardScreen(), HistoryScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
