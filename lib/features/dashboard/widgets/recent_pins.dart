import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/widgets/pin_board.dart';
import '../../../shared/widgets/pop.dart';
import '../../history/providers/history_providers.dart';

/// The songs caught before the latest one, as a small pin board.
class RecentPins extends ConsumerWidget {
  const RecentPins({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(recentRecognitionsProvider).value?.skip(1).toList() ??
        const [];
    if (entries.isEmpty) return const SliverToBoxAdapter();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('recently caught'),
            Masonry(
              heights: [for (final e in entries) pinHeight(e)],
              children: [
                for (final e in entries) PinCard(entry: e, showDay: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
