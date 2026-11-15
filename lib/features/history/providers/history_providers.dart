import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/channel_names.dart';
import '../../../core/models/history.dart';
import '../../../core/platform/sonora_platform.dart';

class HistoryQuery {
  const HistoryQuery({this.text = '', this.sort = HistorySort.newest});

  final String text;
  final HistorySort sort;
}

final historyQueryProvider =
    NotifierProvider<HistoryQueryController, HistoryQuery>(
      HistoryQueryController.new,
    );

class HistoryQueryController extends Notifier<HistoryQuery> {
  @override
  HistoryQuery build() => const HistoryQuery();

  void search(String text) =>
      state = HistoryQuery(text: text.trim(), sort: state.sort);

  void sortBy(HistorySort sort) =>
      state = HistoryQuery(text: state.text, sort: sort);
}

/// Re-runs [ref]'s provider whenever native reports `history_changed`.
void _refreshOnHistoryChange(Ref ref) {
  final subscription = ref
      .watch(sonoraPlatformProvider)
      .events
      .where((e) => e.type == BridgeEventTypes.historyChanged)
      .listen((_) => ref.invalidateSelf(), onError: (Object _) {});
  ref.onDispose(subscription.cancel);
}

/// The history list for the current search and sort.
final historyProvider = FutureProvider<HistoryPage>((ref) {
  _refreshOnHistoryChange(ref);
  final query = ref.watch(historyQueryProvider);
  return ref
      .watch(sonoraPlatformProvider)
      .getRecognitionHistory(
        query: query.text.isEmpty ? null : query.text,
        sort: query.sort,
      );
});

/// The most recent recognition, for the dashboard. Survives app restarts.
final latestRecognitionProvider = FutureProvider<HistoryEntry?>((ref) async {
  _refreshOnHistoryChange(ref);
  final page = await ref
      .watch(sonoraPlatformProvider)
      .getRecognitionHistory(limit: 1);
  return page.entries.firstOrNull;
});

/// The latest few recognitions, for the dashboard's pin board.
final recentRecognitionsProvider = FutureProvider<List<HistoryEntry>>((
  ref,
) async {
  _refreshOnHistoryChange(ref);
  final page = await ref
      .watch(sonoraPlatformProvider)
      .getRecognitionHistory(limit: 7);
  return page.entries;
});

final songDetailProvider = FutureProvider.autoDispose.family<SongDetail, int>((
  ref,
  songId,
) {
  _refreshOnHistoryChange(ref);
  return ref.watch(sonoraPlatformProvider).getSongDetail(songId);
});
