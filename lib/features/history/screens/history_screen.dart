import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/history.dart';
import '../../../core/platform/sonora_platform.dart';
import '../../../shared/utils/formatting.dart';
import '../providers/history_providers.dart';
import '../../../shared/widgets/pin_board.dart';
import '../../../shared/widgets/pop.dart';

/// Every recognition as a pin board, searchable and sortable, grouped by day.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  /// Swiped rows leave the list at once; the database reload follows.
  /// Event IDs are never reused, so this set never hides a new entry.
  final _dismissed = <int>{};

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    setState(() {}); // Show or hide the clear button.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => ref.read(historyQueryProvider.notifier).search(text),
    );
  }

  Future<void> _delete(HistoryEntry entry) async {
    try {
      await ref.read(sonoraPlatformProvider).deleteRecognition(entry.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Removed “${entry.song.title}”')),
        );
    } on PlatformFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't remove that entry")),
      );
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This permanently deletes every song Sonora has recognised on this phone. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(sonoraPlatformProvider).clearRecognitionHistory();
    } on PlatformFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't clear history")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(historyQueryProvider);
    final history = ref.watch(historyProvider);
    final hasHistory = (history.value?.total ?? 0) > 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          PopHeader(
            title: 'your sounds',
            actions: [
              PopupMenuButton<HistorySort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.swap_vert),
                initialValue: query.sort,
                onSelected: ref.read(historyQueryProvider.notifier).sortBy,
                itemBuilder: (_) => [
                  for (final sort in HistorySort.values)
                    PopupMenuItem(value: sort, child: Text(sort.label)),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                enabled: hasHistory,
                onSelected: (_) => _confirmClear(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'clear', child: Text('Clear history')),
                ],
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SearchBar(
                constraints: const BoxConstraints(minHeight: 52),
                controller: _search,
                hintText: 'Search songs, artists, albums',
                leading: const Icon(Icons.search),
                onChanged: _onSearchChanged,
                trailing: [
                  if (_search.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        _onSearchChanged('');
                      },
                    ),
                ],
              ),
            ),
          ),
          ...switch (history) {
            AsyncData(:final value) => _content(context, value, query),
            AsyncError() => [
              const _Message(
                icon: Icons.error_outline,
                title: "Couldn't load history",
                body: 'Pull down on Home to retry.',
              ),
            ],
            _ => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    HistoryPage page,
    HistoryQuery query,
  ) {
    if (page.total == 0) {
      return const [
        _Message(
          icon: Icons.library_music_outlined,
          title: 'No songs yet',
          body: 'Turn on listening or tap Identify song on Home. Everything Sonora recognises is saved here, on your phone only.',
        ),
      ];
    }
    if (page.entries.isEmpty) {
      return [
        _Message(
          icon: Icons.search_off,
          title: 'No matches',
          body: 'Nothing in your history matches “${query.text}”.',
        ),
      ];
    }

    final p = context.palette;
    final entries = [
      for (final e in page.entries)
        if (!_dismissed.contains(e.eventId)) e,
    ];

    Widget pin(HistoryEntry entry) => Dismissible(
      key: ValueKey(entry.eventId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: p.error.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(Icons.delete_outline, color: p.error),
      ),
      onDismissed: (_) {
        setState(() => _dismissed.add(entry.eventId));
        _delete(entry);
      },
      child: PinCard(entry: entry, showDay: !query.sort.isChronological),
    );

    Widget board(List<HistoryEntry> group) => Masonry(
      heights: [for (final e in group) pinHeight(e)],
      children: [for (final e in group) pin(e)],
    );

    final children = <Widget>[];
    if (query.sort.isChronological) {
      // Consecutive entries from the same day share a board.
      var group = <HistoryEntry>[];
      String? day;
      void flush() {
        if (group.isEmpty) return;
        children
          ..add(_DayHeader(day!))
          ..add(board(group));
        group = [];
      }

      for (final entry in entries) {
        final d = Formatting.day(context, entry.recognizedAt);
        if (d != day) {
          flush();
          day = d;
        }
        group.add(entry);
      }
      flush();
    } else {
      children
        ..add(const SizedBox(height: 12))
        ..add(board(entries));
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(children: children),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: PopChip(label.toLowerCase(), color: context.palette.violet),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: context.palette.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
