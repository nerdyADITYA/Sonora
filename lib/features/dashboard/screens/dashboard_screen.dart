import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/bridge_diagnostics_card.dart';
import '../widgets/last_discovery_card.dart';
import '../widgets/listening_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(platformInfoProvider);
          ref.invalidate(listeningStatusProvider);
          await Future.wait([
            ref.read(platformInfoProvider.future).then((_) {}, onError: (_) {}),
            ref
                .read(listeningStatusProvider.future)
                .then((_) {}, onError: (_) {}),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar.large(title: Text('Sonora')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.list(
                children: const [
                  ListeningCard(),
                  SizedBox(height: 12),
                  LastDiscoveryCard(),
                  SizedBox(height: 12),
                  BridgeDiagnosticsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
