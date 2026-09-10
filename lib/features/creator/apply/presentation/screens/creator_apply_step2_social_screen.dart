import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum SlugPlatform { youtube, instagram, tiktok, facebook }

class CreatorApplyStep2SocialScreen extends ConsumerStatefulWidget {
  const CreatorApplyStep2SocialScreen({super.key});

  @override
  ConsumerState<CreatorApplyStep2SocialScreen> createState() =>
      CreatorApplyStep2SocialScreenState();
}

class CreatorApplyStep2SocialScreenState
    extends ConsumerState<CreatorApplyStep2SocialScreen> {
  late final TextEditingController _sampleUrlController;
  late final TextEditingController _totalFollowersController;
  TextEditingController? _engagementRateController;
  late Set<String> _contentKinds;
  late List<String> _sampleUrls;

  TextEditingController get _engagementRateControllerSafe =>
      _engagementRateController ??= TextEditingController();

  Map<String, SocialAccount> _connectedById = const {};

  @override
  void initState() {
    super.initState();
    final initial = ref.read(creatorFormProvider);
    _sampleUrlController = TextEditingController();
    _totalFollowersController = TextEditingController(
      text: initial.totalFollowers,
    );
    _engagementRateController = TextEditingController(
      text: initial.engagementRate,
    );
    _contentKinds = {...initial.contentKinds};
    _sampleUrls = [...initial.sampleUrls];

    // Reapply prefill: hydrate _connectedById from platforms on form.
    _connectedById = {
      for (final p in initial.platforms)
        if (_slugToPlatform(p.id) != null)
          p.id: SocialAccount(
            id: p.id,
            platform: _slugToPlatform(p.id)!,
            handle: p.handle,
            username: p.handle.replaceAll('@', ''),
            displayName: p.name,
            avatarUrl: p.profileUrl,
            followerCount: p.followerCount,
            isConnected: true,
          ),
    };
    _refreshConnectedFromNotifier();
  }

  @override
  void dispose() {
    _sampleUrlController.dispose();
    _totalFollowersController.dispose();
    _engagementRateController?.dispose();
    super.dispose();
  }

  bool get canProceed => true;

  String _buildProfileUrl(SlugPlatform? slug, SocialAccount account) {
    final id = account.username.trim();
    final handle = account.handle.trim().replaceAll('@', '');
    if (slug == null) return '';
    final key = id.isNotEmpty ? id : handle;
    if (key.isEmpty) return '';
    switch (slug) {
      case SlugPlatform.youtube:
        return 'https://www.youtube.com/channel/';
      case SlugPlatform.instagram:
        return 'https://www.instagram.com/';
      case SlugPlatform.tiktok:
        return 'https://www.tiktok.com/@';
      case SlugPlatform.facebook:
        return 'https://www.facebook.com/';
    }
  }

  Future<bool> save() async {
    final platforms = <Platform>[
      for (final entry in _connectedById.entries)
        Platform(
          id: entry.key,
          name: entry.value.platform.displayName,
          handle: entry.value.handle,
          followerCount: entry.value.followerCount,
          profileUrl: _buildProfileUrl(_slugToSlug(entry.key), entry.value),
          connected: true,
        ),
    ];
    final entered = _engagementRateControllerSafe.text.trim();
    final engagementId = entered.isEmpty
        ? ''
        : kEngagementRates
              .firstWhere(
                (e) => e.label == entered,
                orElse: () => const EngagementRateOption('', ''),
              )
              .value;
    ref
        .read(creatorFormProvider.notifier)
        .saveStep2(
          platforms: platforms,
          totalFollowers: _totalFollowersController.text.trim(),
          audienceBand: ref.read(creatorFormProvider).audienceBand,
          engagementRate: engagementId,
          contentKinds: _contentKinds,
          sampleUrls: _sampleUrls,
        );
    return true;
  }

  void _refreshConnectedFromNotifier() {
    final state = ref.read(socialConnectNotifierProvider);
    final accounts = state.maybeWhen(
      loadSuccess: (a) => a,
      orElse: () => const <SocialAccount>[],
    );
    final next = <String, SocialAccount>{};
    for (final opt in kCreatorPlatforms) {
      SocialAccount? match;
      for (final a in accounts) {
        if (a.isConnected && _slugToPlatform(opt.id) == a.platform) {
          match = a;
          break;
        }
      }
      if (match != null) next[opt.id] = match;
    }
    if (mounted) {
      setState(() => _connectedById = next);
      Future.microtask(() {
        if (mounted) save();
      });
    }
  }

  SocialPlatform? _slugToPlatform(String id) => switch (id) {
    'instagram' => SocialPlatform.instagram,
    'tiktok' => SocialPlatform.tiktok,
    'youtube' => SocialPlatform.youtube,
    'facebook' => SocialPlatform.facebook,
    _ => null,
  };

  SlugPlatform? _slugToSlug(String id) => switch (id) {
    'instagram' => SlugPlatform.instagram,
    'tiktok' => SlugPlatform.tiktok,
    'youtube' => SlugPlatform.youtube,
    'facebook' => SlugPlatform.facebook,
    _ => null,
  };

  Future<void> _onConnectPlatform(CreatorPlatformOption opt) async {
    if (_connectedById.containsKey(opt.id)) {
      SmSnackbar.info(context, '${opt.name} is already connected.');
      return;
    }
    final platform = _slugToPlatform(opt.id);
    if (platform == null) return;
    final failure = await ref
        .read(socialConnectNotifierProvider.notifier)
        .connect(platform);
    if (failure != null && mounted) {
      SmSnackbar.error(
        context,
        'Could not connect ${opt.name}. Please try again.',
      );
    }
  }

  void _addSampleUrl() {
    final url = _sampleUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _sampleUrls.add(url);
      _sampleUrlController.clear();
    });
  }

  void _removeSampleUrl(int index) {
    setState(() => _sampleUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Social Media Profiles',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s6),
              const Text(
                'Connect at least one social media profile to help us verify '
                'your creator status.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s6),
              const Text(
                'Connect Social Media Profile',
                style: DesignTokens.oneLinerSemibold,
              ),
              const SizedBox(height: DesignTokens.s4),
              const Text(
                'Click a social media icon below to connect your '
                'account. At least one is required.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s16),
              _PlatformIconRow(
                onTapPlatform: _onConnectPlatform,
                connectedIds: _connectedById.keys.toSet(),
              ),
              const SizedBox(height: DesignTokens.s24),
              const Text(
                'Audience Metrics',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s16),
              TextField(
                controller: _totalFollowersController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Total Followers/Subscribers',
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              TextField(
                controller: _engagementRateControllerSafe,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Average Engagement Rate',
                  suffixIcon: SizedBox(
                    width: 48,
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: DesignTokens.inputFieldDropdownIcon,
                      ),
                      color: DesignTokens.bgAppBody,
                      onSelected: (value) {
                        _engagementRateControllerSafe.text = value;
                      },
                      itemBuilder: (_) => [
                        for (final option in kEngagementRates)
                          PopupMenuItem(
                            value: option.label,
                            child: Text(option.label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              const Text(
                'Content Type',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s16),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final k in kContentKinds)
                    _ContentKindChip(
                      label: k.label,
                      selected: _contentKinds.contains(k.id),
                      onTap: () => setState(() {
                        if (_contentKinds.contains(k.id)) {
                          _contentKinds.remove(k.id);
                        } else {
                          _contentKinds.add(k.id);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s24),
              const Text(
                'Sample Content (Optional)',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s6),
              const Text(
                'Share 3-5 of your best-performing posts.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sampleUrlController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: DesignTokens.inputFieldData,
                      ),
                      cursorColor: DesignTokens.primaryGreen,
                      decoration: DesignTokens.inputDecoration(
                        hintText: 'Post URL',
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _AddButton(onPressed: _addSampleUrl),
                ],
              ),
              const SizedBox(height: DesignTokens.s16),
              for (var i = 0; i < _sampleUrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                  child: _SampleUrlRow(
                    url: _sampleUrls[i],
                    onRemove: () => _removeSampleUrl(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}

class _PlatformIconRow extends StatelessWidget {
  const _PlatformIconRow({
    required this.onTapPlatform,
    required this.connectedIds,
  });

  final void Function(CreatorPlatformOption) onTapPlatform;
  final Set<String> connectedIds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final opt in kCreatorPlatforms)
          _PlatformBadge(
            option: opt,
            isConnected: connectedIds.contains(opt.id),
            onTap: () => onTapPlatform(opt),
          ),
      ],
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({
    required this.option,
    this.isConnected = false,
    this.onTap,
  });

  final CreatorPlatformOption option;
  final bool isConnected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Material(
      color: const Color(0xFF3F3F42),
      shape: const CircleBorder(
        side: BorderSide(color: DesignTokens.inputFieldBorder),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: SvgPicture.asset(
              option.assetPath,
              width: 44,
              height: 44,
              placeholderBuilder: (_) => Icon(
                option.icon,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ),
      ),
    );
    if (!isConnected) return badge;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Center(child: badge)),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: DesignTokens.bgAppBody, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentKindChip extends StatelessWidget {
  const _ContentKindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: selected
            ? DesignTokens.chipDecorationSelected()
            : DesignTokens.chipDecorationDefault(),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.chipsDefaultText,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: DesignTokens.bgAppBodyLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(
            Icons.add_rounded,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
    );
  }
}

class _SampleUrlRow extends StatelessWidget {
  const _SampleUrlRow({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.inputFieldFill,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              border: Border.all(color: DesignTokens.inputFieldBorder),
            ),
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: DesignTokens.inputFieldData,
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: DesignTokens.bgAppBodyLight,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Icon(
                Icons.delete_rounded,
                size: 19,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
