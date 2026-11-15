import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/sonora_palette.dart';
import '../../../../core/errors/platform_failure.dart';
import '../../../../core/models/spotify.dart';
import '../../../../core/platform/sonora_platform.dart';
import '../../../../shared/widgets/album_artwork.dart';
import '../../../recognition/recognition_error_copy.dart';
import '../providers/spotify_controller.dart';

const defaultNewPlaylistName = 'Sonora discoveries';

/// Lets the user pick one of their playlists, or create "Sonora discoveries".
Future<SpotifyPlaylist?> showPlaylistPicker(BuildContext context) =>
    showModalBottomSheet<SpotifyPlaylist>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.surface,
      builder: (_) => const _PlaylistPicker(),
    );

class _PlaylistPicker extends ConsumerStatefulWidget {
  const _PlaylistPicker();

  @override
  ConsumerState<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends ConsumerState<_PlaylistPicker> {
  var _creating = false;

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final playlist = await ref
          .read(sonoraPlatformProvider)
          .createSpotifyPlaylist(defaultNewPlaylistName);
      if (mounted) Navigator.pop(context, playlist);
    } on PlatformFailure catch (f) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recognitionErrorDetail(f.code) ?? f.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlists = ref.watch(spotifyPlaylistsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Choose a playlist', style: theme.textTheme.titleLarge),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: CircleAvatar(
              backgroundColor: context.palette.accent,
              foregroundColor: context.palette.onAccent,
              child: const Icon(Icons.add),
            ),
            title: const Text('New playlist: $defaultNewPlaylistName'),
            subtitle: const Text('Private, in your Spotify library'),
            trailing: _creating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _creating ? null : _create,
          ),
          const Divider(indent: 24, endIndent: 24),
          ...switch (playlists) {
            AsyncData(:final value) when value.playlists.isEmpty => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('You have no playlists you can add to yet.'),
              ),
            ],
            AsyncData(:final value) => [
              for (final p in value.playlists)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: AlbumArtwork(url: p.imageUrl, size: 48, radius: 8),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${p.trackCount} ${p.trackCount == 1 ? 'song' : 'songs'}',
                  ),
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
            AsyncError(:final error) => [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error is PlatformFailure
                      ? recognitionErrorDetail(error.code) ?? error.message
                      : "Couldn't load your playlists.",
                ),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
          if (playlists.value case final page? when page.hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                '${page.hiddenCount} more ${page.hiddenCount == 1 ? 'playlist is' : 'playlists are'} hidden: '
                'another Spotify account owns ${page.hiddenCount == 1 ? 'it' : 'them'}, and Spotify only lets '
                'apps add to your own or collaborative playlists.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
