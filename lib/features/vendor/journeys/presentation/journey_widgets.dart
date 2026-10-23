import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/data/vendor_journeys_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A failure as a sentence, journey error codes first.
String journeyFailureMessage(ServiceFailure failure) =>
    serviceFailureMessage(failure, specific: journeyErrorMessage);

void showJourneySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// A reel thumbnail, or a plain tile when there is none.
class JourneyThumb extends StatelessWidget {
  const JourneyThumb({required this.url, this.size = 56, super.key});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size * 1.4,
        child: ColoredBox(
          color: DesignTokens.bgAppBodyLight,
          child: image == null || image.isEmpty
              ? const Icon(
                  Icons.movie_outlined,
                  color: DesignTokens.textMuted,
                  size: 20,
                )
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.movie_outlined,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Keys for the sheets below.
abstract final class JourneySheetKeys {
  static Key reelOption(String reelId) => Key('journey-reel-option-$reelId');
  static const Key reelConfirm = Key('journey-reel-confirm');
  static const Key vendorSearch = Key('journey-vendor-search');
  static Key vendorResult(String id) => Key('journey-vendor-result-$id');
  static const Key inviteNote = Key('journey-invite-note');
  static const Key inviteSend = Key('journey-invite-send');
}

/// The list of my published reels to pick from; [selected] is ticked.
/// Reels that cannot be used (already in 3 journeys) are shown greyed with
/// the reason.
class JourneyReelPickerList extends ConsumerWidget {
  const JourneyReelPickerList({
    required this.journeyId,
    required this.selected,
    required this.onSelected,
    this.shrinkWrap = false,
    super.key,
  });

  /// '' for a journey not created yet.
  final String journeyId;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(journeyReelOptionsProvider(journeyId));
    return options.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(DesignTokens.s24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ServiceLoadFailureView(
        error: error,
        settingUpTitle: 'Journeys are being set up',
        specific: journeyErrorMessage,
        onRetry: () => ref.invalidate(journeyReelOptionsProvider(journeyId)),
      ),
      data: (reels) {
        if (reels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: Text(
              'You have no published reels yet. Publish a reel from your '
              'reel studio, then add it to a journey.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: reels.length,
          separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s8),
          itemBuilder: (context, i) {
            final reel = reels[i];
            final isSelected = reel.reelId == selected;
            final caption = reel.caption?.trim();
            return Opacity(
              opacity: reel.canUse ? 1 : 0.5,
              child: Material(
                color: DesignTokens.bgAppBody,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  side: BorderSide(
                    color: isSelected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.borderDefault,
                  ),
                ),
                child: InkWell(
                  key: JourneySheetKeys.reelOption(reel.reelId),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  onTap: reel.canUse ? () => onSelected(reel.reelId) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.s8),
                    child: Row(
                      children: [
                        JourneyThumb(url: reel.thumbnailUrl, size: 44),
                        const SizedBox(width: DesignTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                caption == null || caption.isEmpty
                                    ? 'Untitled reel'
                                    : caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DesignTokens.smallRegular,
                              ),
                              const SizedBox(height: DesignTokens.s4),
                              Text(
                                reel.canUse
                                    ? reel.journeyCount == 0
                                          ? 'Not in a journey yet'
                                          : 'In ${reel.journeyCount} '
                                                '${reel.journeyCount == 1 ? 'journey' : 'journeys'}'
                                    : journeyErrorMessage(reel.reason ?? '') ??
                                          'This reel cannot be used.',
                                style: DesignTokens.tiny.copyWith(
                                  color: DesignTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: DesignTokens.primaryGreen,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Asks the vendor to pick one of their reels. Returns its id, or null.
Future<String?> pickJourneyReel(
  BuildContext context, {
  required String journeyId,
  required String title,
  required String confirmLabel,
  String? current,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppFoundation,
  builder: (ctx) => _ReelPickerSheet(
    journeyId: journeyId,
    title: title,
    confirmLabel: confirmLabel,
    current: current,
  ),
);

class _ReelPickerSheet extends StatefulWidget {
  const _ReelPickerSheet({
    required this.journeyId,
    required this.title,
    required this.confirmLabel,
    this.current,
  });

  final String journeyId;
  final String title;
  final String confirmLabel;
  final String? current;

  @override
  State<_ReelPickerSheet> createState() => _ReelPickerSheetState();
}

class _ReelPickerSheetState extends State<_ReelPickerSheet> {
  late String? _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s12),
              Expanded(
                child: JourneyReelPickerList(
                  journeyId: widget.journeyId,
                  selected: _selected,
                  onSelected: (id) => setState(() => _selected = id),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              ServiceActionButton(
                key: JourneySheetKeys.reelConfirm,
                label: widget.confirmLabel,
                onPressed: _selected == null || _selected == widget.current
                    ? null
                    : () => Navigator.of(context).pop(_selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the invite sheet returns.
typedef JourneyInviteChoice = ({JourneyVendor vendor, String? note});

/// Search businesses by name and pick one to invite, with an optional note.
Future<JourneyInviteChoice?> pickJourneyInvitee(BuildContext context) =>
    showModalBottomSheet<JourneyInviteChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppFoundation,
      builder: (ctx) => const _InviteSheet(),
    );

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _note = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  ServiceFailure? _failure;
  List<JourneyVendor> _results = const [];
  JourneyVendor? _picked;
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _note.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(text.trim()));
    });
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    _query = query;
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _failure = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final result = await ref
        .read(vendorJourneysApiProvider)
        .searchVendors(query);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      result.fold(
        (f) {
          _failure = f;
          _results = const [];
        },
        (vendors) {
          _failure = null;
          _results = vendors;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: picked == null ? _searchView() : _noteView(picked),
          ),
        ),
      ),
    );
  }

  Widget _searchView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Invite a business', style: DesignTokens.mediumSemibold),
      const SizedBox(height: DesignTokens.s4),
      Text(
        'They add one of their own reels as a step. It shows once they accept.',
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
      ),
      const SizedBox(height: DesignTokens.s12),
      TextField(
        key: JourneySheetKeys.vendorSearch,
        autofocus: true,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (text) => unawaited(_search(text.trim())),
        decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Business name',
        ),
      ),
      const SizedBox(height: DesignTokens.s12),
      Expanded(child: _resultsView()),
    ],
  );

  Widget _resultsView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final failure = _failure;
    if (failure != null) {
      return Center(
        child: failure.isNotDeployed
            ? const ServiceSettingUpView(title: 'Journeys are being set up')
            : Text(journeyFailureMessage(failure), textAlign: TextAlign.center),
      );
    }
    if (_query.length < 2) {
      return Center(
        child: Text(
          'Type at least 2 letters of a business name.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No business called "$_query".',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final vendor = _results[i];
        final city = vendor.city;
        return ListTile(
          key: JourneySheetKeys.vendorResult(vendor.vendorAccountId),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: DesignTokens.bgAppBodyLight,
            foregroundImage: vendor.logoUrl == null
                ? null
                : NetworkImage(vendor.logoUrl!),
            child: Text(
              vendor.businessName.isEmpty
                  ? '?'
                  : vendor.businessName.characters.first.toUpperCase(),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  vendor.businessName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vendor.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: DesignTokens.colorInfo,
                ),
              ],
            ],
          ),
          subtitle: Text(
            city == null ? vendor.categoryLabel : '${vendor.categoryLabel} · $city',
          ),
          onTap: () => setState(() => _picked = vendor),
        );
      },
    );
  }

  Widget _noteView(JourneyVendor vendor) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          IconButton(
            tooltip: 'Back to search',
            onPressed: () => setState(() => _picked = null),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'Invite ${vendor.businessName}',
              style: DesignTokens.mediumSemibold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: DesignTokens.s12),
      TextField(
        key: JourneySheetKeys.inviteNote,
        controller: _note,
        maxLength: 280,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Join our Pokhara weekend?',
        ),
      ),
      const Spacer(),
      ServiceActionButton(
        key: JourneySheetKeys.inviteSend,
        label: 'Send invite',
        icon: Icons.send_rounded,
        onPressed: () => Navigator.of(context).pop((
          vendor: vendor,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        )),
      ),
    ],
  );
}

/// Title and city, for creating or editing a journey.
class JourneyTitleFields extends StatelessWidget {
  const JourneyTitleFields({
    required this.title,
    required this.city,
    super.key,
  });

  static const Key titleKey = Key('journey-title-field');
  static const Key cityKey = Key('journey-city-field');

  final TextEditingController title;
  final TextEditingController city;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        key: titleKey,
        controller: title,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Title (optional)',
          hintText: 'Kathmandu → Pokhara weekend',
        ),
      ),
      TextField(
        key: cityKey,
        controller: city,
        maxLength: 80,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'City (optional)',
          hintText: 'Pokhara',
        ),
      ),
    ],
  );
}

/// Edit the title and city. Returns the pair, or null when cancelled.
Future<({String title, String city})?> editJourneyTitle(
  BuildContext context, {
  String? title,
  String? city,
}) => showDialog<({String title, String city})>(
  context: context,
  builder: (ctx) => _EditTitleDialog(title: title, city: city),
);

class _EditTitleDialog extends StatefulWidget {
  const _EditTitleDialog({this.title, this.city});

  final String? title;
  final String? city;

  @override
  State<_EditTitleDialog> createState() => _EditTitleDialogState();
}

class _EditTitleDialogState extends State<_EditTitleDialog> {
  late final _title = TextEditingController(text: widget.title ?? '');
  late final _city = TextEditingController(text: widget.city ?? '');

  static const Key saveKey = Key('journey-title-save');

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Title and city'),
    content: SingleChildScrollView(
      child: JourneyTitleFields(title: _title, city: _city),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        key: saveKey,
        onPressed: () => Navigator.of(
          context,
        ).pop((title: _title.text.trim(), city: _city.text.trim())),
        child: const Text('Save'),
      ),
    ],
  );
}
