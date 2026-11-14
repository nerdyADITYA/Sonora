import 'package:material_ui/material_ui.dart';

/// Date and time labels using Material's localisations (no intl dependency).
abstract final class Formatting {
  static String time(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(value));

  /// "Today", "Yesterday", or a medium date such as "Mon, Nov 10".
  static String day(BuildContext context, DateTime value, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final date = DateUtils.dateOnly(value);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    final localizations = MaterialLocalizations.of(context);
    return date.year == today.year
        ? localizations.formatMediumDate(date)
        : localizations.formatFullDate(date);
  }

  static String dayAndTime(BuildContext context, DateTime value) =>
      '${day(context, value)}, ${time(context, value)}';

  /// 3:25 style track length.
  static String duration(int milliseconds) {
    final total = Duration(milliseconds: milliseconds);
    final seconds = (total.inSeconds % 60).toString().padLeft(2, '0');
    return total.inHours > 0
        ? '${total.inHours}:${(total.inMinutes % 60).toString().padLeft(2, '0')}:$seconds'
        : '${total.inMinutes}:$seconds';
  }
}
