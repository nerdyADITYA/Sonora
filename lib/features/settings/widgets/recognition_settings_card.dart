import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/platform_failure.dart';
import '../../../core/models/recognition_provider.dart';
import '../providers/recognition_provider_controller.dart';

/// The ACRCloud project Sonora identifies songs with. Each user brings their
/// own keys; they are stored encrypted on the phone and never shown again.
class RecognitionSettingsCard extends ConsumerWidget {
  const RecognitionSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(recognitionProviderProvider).value;

    if (provider != null && !provider.sdkAvailable) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.graphic_eq),
          title: Text('Recognition unavailable'),
          subtitle: Text(
            'This build has no ACRCloud SDK. See docs/DEVELOPMENT.md to add it.',
          ),
        ),
      );
    }

    final (title, subtitle) = switch (provider?.source) {
      KeySource.settings => (
        'Your ACRCloud project',
        provider?.host ?? 'Keys saved',
      ),
      KeySource.build => (
        'Built-in ACRCloud keys',
        'From this build. Keys you enter here take priority.',
      ),
      KeySource.none => (
        'Set up ACRCloud',
        'Sonora needs your own ACRCloud project keys to identify songs.',
      ),
      null => ('ACRCloud', 'Loading…'),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: Text(title),
            subtitle: Text(
              subtitle,
              style: provider?.configured == false
                  ? const TextStyle(color: AppColors.warning)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(
              provider?.source == KeySource.settings
                  ? 'Change ACRCloud keys'
                  : 'Enter ACRCloud keys',
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _KeysDialog(),
            ),
          ),
          if (provider?.source == KeySource.settings)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove keys'),
              onTap: () => _remove(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recognitionProviderProvider.notifier).remove();
    messenger.showSnackBar(
      const SnackBar(content: Text('ACRCloud keys removed from this phone.')),
    );
  }
}

class _KeysDialog extends ConsumerStatefulWidget {
  const _KeysDialog();

  @override
  ConsumerState<_KeysDialog> createState() => _KeysDialogState();
}

class _KeysDialogState extends ConsumerState<_KeysDialog> {
  final _host = TextEditingController();
  final _key = TextEditingController();
  final _secret = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _host.dispose();
    _key.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(recognitionProviderProvider.notifier)
          .save(
            host: _host.text,
            accessKey: _key.text,
            accessSecret: _secret.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('ACRCloud keys saved on this phone.')),
      );
    } on PlatformFailure catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ACRCloud keys'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a free Audio & Video Recognition project at '
              'console.acrcloud.com with the music bucket, then copy its '
              'host, access key and access secret. They are stored '
              'encrypted on this phone and are not shown again.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _host,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'identify-eu-west-1.acrcloud.com',
              ),
              autocorrect: false,
              keyboardType: TextInputType.url,
            ),
            TextField(
              controller: _key,
              decoration: const InputDecoration(labelText: 'Access key'),
              autocorrect: false,
              enableSuggestions: false,
            ),
            TextField(
              controller: _secret,
              decoration: const InputDecoration(labelText: 'Access secret'),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.warning)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
