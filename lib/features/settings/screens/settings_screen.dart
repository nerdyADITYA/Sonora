import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/sonora_palette.dart';
import '../../../shared/widgets/pop.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../integrations/spotify/widgets/spotify_card.dart';
import '../widgets/appearance_card.dart';
import '../widgets/listening_settings_card.dart';
import '../widgets/privacy_settings_card.dart';
import '../widgets/recognition_settings_card.dart';

/// Settings: look, ACRCloud keys, Spotify, the Quick Settings tile, battery
/// and privacy.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(platformInfoProvider).value?.appVersion;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const PopHeader(title: 'settings'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                const SectionLabel('appearance'),
                const AppearanceCard(),
                const SizedBox(height: 28),
                const SectionLabel('recognition'),
                const RecognitionSettingsCard(),
                const SizedBox(height: 28),
                const SectionLabel('music services'),
                const SpotifyCard(),
                const SizedBox(height: 28),
                const SectionLabel('ambient listening'),
                const ListeningSettingsCard(),
                const SizedBox(height: 28),
                const SectionLabel('privacy'),
                const PrivacySettingsCard(),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'Sonora ${version ?? ''}'.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
