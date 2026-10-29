import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/theme.dart';
import '../../controllers/contentController.dart';
import '../../controllers/donationController.dart';
import '../../controllers/mlSettingsController.dart';
import '../../controllers/storeLinksController.dart';
import '../../models/donationSettings.dart';
import '../../models/storeLinks.dart';
import '../../widgets/customSnackbar.dart';
import '../../widgets/ui.dart';

/// Switches that change the app without a release: content refresh, the
/// Practice button, donation prompts and the Share App store links. Replaces the separate ML Settings
/// and Donations tabs.
class AppControlsTab extends StatefulWidget {
  const AppControlsTab({super.key});

  @override
  State<AppControlsTab> createState() => _AppControlsTabState();
}

class _AppControlsTabState extends State<AppControlsTab> {
  final TextEditingController _url = TextEditingController();
  bool _urlSeeded = false;

  bool _donationsSeeded = false;
  bool _donationsEnabled = true;
  final Map<String, bool> _shown = {
    for (final key in DonationSettings.placements.keys) key: true,
  };

  final TextEditingController _playStore = TextEditingController();
  final TextEditingController _appStore = TextEditingController();
  bool _linksSeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MLSettingsController>().getMLSettings();
      Get.find<DonationController>().load();
      Get.find<StoreLinksController>().load();
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _playStore.dispose();
    _appStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminPage(
        title: 'App controls',
        subtitle: 'Changes here reach phones without an app update.',
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _contentCard(),
            const SizedBox(height: Space.lg),
            _practiceCard(),
            const SizedBox(height: Space.lg),
            _donationsCard(),
            const SizedBox(height: Space.lg),
            _storeLinksCard(),
          ],
        ),
      ),
    );
  }

  // ---- Content ---------------------------------------------------------------

  Widget _contentCard() {
    return GetBuilder<ContentController>(
      builder: (content) => AdminCard(
        title: 'App content',
        subtitle: 'Phones keep categories, sections and duas on the device and '
            'download them again only when told content changed (or once a '
            'day). Every save in this panel tells them automatically.',
        trailing: AdminButton.secondary(
          label: 'Send to phones now',
          icon: Icons.sync_rounded,
          busy: content.publishing,
          onPressed: () async {
            final ok = await content.publish();
            CustomSnackbar.show(
              ok ? 'Phones told' : "Couldn't reach Firestore",
              ok
                  ? 'Every phone downloads content again on its next launch.'
                  : 'Try again in a moment.',
              isSuccess: ok,
            );
          },
        ),
        child: Wrap(
          spacing: Space.xl,
          runSpacing: Space.md,
          children: [
            _fact('Content version', '${content.version ?? 'not set yet'}'),
            _fact(
              'Last sent',
              content.publishedAt == null
                  ? 'never: phones only refresh once a day'
                  : relativeTime(content.publishedAt!),
            ),
            if (content.pending)
              const StatusChip('Sending changes…',
                  tone: Tone.warning, icon: Icons.sync_rounded),
          ],
        ),
      ),
    );
  }

  Widget _fact(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AdminText.label),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );

  // ---- Practice --------------------------------------------------------------

  Widget _practiceCard() {
    return GetBuilder<MLSettingsController>(
      builder: (ml) {
        final settings = ml.mlSettings;
        if (!_urlSeeded && settings != null) {
          _urlSeeded = true;
          _url.text = settings.baseUrl;
        }
        final enabled = settings?.practiceEnabled ?? true;
        final insecure = _url.text.trim().startsWith('http://');
        return AdminCard(
          title: 'Practice button',
          subtitle: 'Readers record themselves reciting and a transcription '
              'server checks it.',
          trailing: ml.isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: enabled,
                title: Text(
                  enabled ? 'Active in the app' : 'Greyed out in the app',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Off greys out Practice on every dua; tapping it tells '
                  'readers it is coming soon. Applies within seconds.',
                  style: AdminText.muted,
                ),
                onChanged: ml.isLoading ? null : ml.setPracticeEnabled,
              ),
              const SizedBox(height: Space.lg),
              const FieldLabel('Transcription server'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _url,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/transcribe/',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  AdminButton(
                    label: 'Save',
                    onPressed: ml.isLoading ||
                            _url.text.trim() == (settings?.baseUrl ?? '')
                        ? null
                        : () {
                            final uri = Uri.tryParse(_url.text.trim());
                            if (uri == null ||
                                !uri.hasScheme ||
                                uri.host.isEmpty) {
                              CustomSnackbar.show('Check the address',
                                  'Enter a full URL, e.g. https://example.com/transcribe/',
                                  isSuccess: false);
                              return;
                            }
                            ml.saveUrl(_url.text.trim());
                          },
                  ),
                ],
              ),
              if (insecure) ...[
                const SizedBox(height: Space.sm),
                const _Note(
                  icon: Icons.warning_amber_rounded,
                  tone: Tone.warning,
                  text: 'This address uses http. Android blocks plain-http '
                      'requests from apps by default, so Practice may fail '
                      'on phones. Use an https address.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---- Donations -------------------------------------------------------------

  static const Map<String, String> _hints = {
    'home': 'The "Support LearningSouls" card on the home screen.',
    'search': 'The card under the quick filters on the Search screen.',
    'searchPill': 'The small Donate button in the Search screen header.',
    'prayer': 'The card at the bottom of the Prayer Times screen.',
    'settings': 'The Donate row in Settings, under Support.',
    'reminder': 'The weekly Friday notification, and its switch in Settings.',
  };

  Widget _donationsCard() {
    return GetBuilder<DonationController>(
      builder: (donations) {
        if (donations.loaded && !_donationsSeeded) {
          _donationsSeeded = true;
          _donationsEnabled = donations.settings.enabled;
          for (final key in DonationSettings.placements.keys) {
            _shown[key] = donations.settings.isOn(key);
          }
        }
        final draft =
            DonationSettings(enabled: _donationsEnabled, shown: Map.of(_shown));
        final dirty = donations.loaded &&
            (draft.enabled != donations.settings.enabled ||
                DonationSettings.placements.keys
                    .any((k) => draft.isOn(k) != donations.settings.isOn(k)));

        return AdminCard(
          title: 'Donation prompts',
          subtitle: 'Where the app asks readers to support it.',
          trailing: AdminButton(
            label: 'Publish',
            icon: Icons.check_rounded,
            busy: donations.loading,
            onPressed: dirty ? () => donations.save(draft) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _donationsEnabled,
                title: const Text('Show donation prompts',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    'Off hides every prompt below, whatever its own switch.',
                    style: AdminText.muted),
                onChanged: (v) => setState(() => _donationsEnabled = v),
              ),
              const Divider(height: Space.xl),
              for (final MapEntry(key: key, value: label)
                  in DonationSettings.placements.entries)
                Opacity(
                  opacity: _donationsEnabled ? 1 : 0.45,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _shown[key]!,
                    title: Text(label),
                    subtitle: Text(_hints[key] ?? '', style: AdminText.muted),
                    onChanged: (v) => setState(() => _shown[key] = v),
                  ),
                ),
              if (dirty)
                const Padding(
                  padding: EdgeInsets.only(top: Space.sm),
                  child: _Note(
                    icon: Icons.info_outline_rounded,
                    tone: Tone.info,
                    text:
                        'Not published yet. Phones change when you press Publish.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---- Store links -----------------------------------------------------------

  Widget _storeLinksCard() {
    return GetBuilder<StoreLinksController>(
      builder: (store) {
        if (store.loaded && !_linksSeeded) {
          _linksSeeded = true;
          _playStore.text = store.links.playStore;
          _appStore.text = store.links.appStore;
        }
        final draft = StoreLinks.fromMap({
          'playStore': _playStore.text,
          'appStore': _appStore.text,
        });
        final dirty = store.loaded &&
            (draft.playStore != store.links.playStore ||
                draft.appStore != store.links.appStore);

        return AdminCard(
          title: 'Share App links',
          subtitle: 'The store page in the message readers send from '
              'Settings → Share App. Android phones share the Play Store '
              'link, iPhones the App Store link.',
          trailing: AdminButton(
            label: 'Publish',
            icon: Icons.check_rounded,
            busy: store.loading,
            onPressed: dirty
                ? () {
                    for (final link in [draft.playStore, draft.appStore]) {
                      final uri = Uri.tryParse(link);
                      if (uri == null ||
                          uri.scheme != 'https' ||
                          uri.host.isEmpty) {
                        CustomSnackbar.show('Check the address',
                            'Enter a full https link, e.g. $link',
                            isSuccess: false);
                        return;
                      }
                    }
                    store.save(draft);
                  }
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Google Play'),
              TextField(
                controller: _playStore,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: StoreLinks.defaultPlayStore,
                ),
              ),
              const SizedBox(height: Space.lg),
              const FieldLabel('App Store'),
              TextField(
                controller: _appStore,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: StoreLinks.defaultAppStore,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text('Leave a field empty to use the link shown in it.',
                  style: AdminText.muted),
            ],
          ),
        );
      },
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.tone, required this.text});
  final IconData icon;
  final Tone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tone.color.withValues(alpha: 0.08),
        borderRadius: Radii.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone.color),
          const SizedBox(width: Space.sm),
          Expanded(
            child:
                Text(text, style: TextStyle(color: tone.color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
