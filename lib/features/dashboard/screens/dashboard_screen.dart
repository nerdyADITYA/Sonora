import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../shared/widgets/pop.dart';
import '../../history/providers/history_providers.dart';
import '../../listening/providers/listening_controller.dart';
import '../../recognition/widgets/recognize_card.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/last_discovery_card.dart';
import '../widgets/listening_card.dart';
import '../widgets/recent_pins.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(platformInfoProvider);
          ref.invalidate(recentRecognitionsProvider);
          await Future.wait([
            ref.read(listeningControllerProvider.notifier).refresh(),
            ref.read(platformInfoProvider.future).then((_) {}, onError: (_) {}),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            PopHeader(
              eyebrow: Row(
                children: [
                  const WaveformLogo(size: 26),
                  const SizedBox(width: 8),
                  Text('Sonora', style: theme.textTheme.titleLarge),
                ],
              ),
              title: "what's that\nsong?",
              actions: [
                IconButton.outlined(
                  tooltip: dark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  style: IconButton.styleFrom(
                    backgroundColor: p.yellow,
                    foregroundColor: p.onPop,
                    side: BorderSide(color: p.ink, width: 2),
                  ),
                  icon: Icon(
                    dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  ),
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .toggle(theme.brightness),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  ListeningCard(),
                  SizedBox(height: 16),
                  RecognizeCard(),
                  SizedBox(height: 28),
                  SectionLabel('last caught ✦'),
                  LastDiscoveryCard(),
                  SizedBox(height: 28),
                ]),
              ),
            ),
            const RecentPins(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
