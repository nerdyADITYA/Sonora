import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/platform_failure.dart';
import '../providers/dashboard_providers.dart';

/// Shows what the Kotlin bridge reports, proving Flutter <-> native communication.
class BridgeDiagnosticsCard extends ConsumerWidget {
  const BridgeDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = ref.watch(platformInfoProvider);
    final connected = ref.watch(bridgeConnectedProvider);

    final (eventLabel, eventColor) = switch (connected) {
      AsyncData(value: true) => ('Connected', AppColors.success),
      AsyncError() => ('Unavailable', AppColors.error),
      _ => ('Waiting', AppColors.warning),
    };

    final rows = switch (info) {
      AsyncData(:final value) => [
        _Row('Device', value.displayName),
        _Row('Android', '${value.androidVersion} (API ${value.sdkInt})'),
        if (value.securityPatch != null)
          _Row('Security patch', value.securityPatch!),
        _Row('Samsung device', value.isSamsung ? 'Yes' : 'No'),
        if (value.appVersion != null) _Row('Sonora', value.appVersion!),
      ],
      AsyncError(:final error) => [
        _Row('Method channel', error is PlatformFailure ? error.code : 'Error'),
      ],
      _ => [const _Row('Method channel', 'Loading…')],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NATIVE BRIDGE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: eventColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Event channel: $eventLabel',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
