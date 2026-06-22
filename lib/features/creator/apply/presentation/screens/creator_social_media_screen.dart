import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _Platform {
  final String id;
  final String label;
  final Color bgColor;
  final Color iconColor;
  const _Platform(this.id, this.label, this.bgColor, this.iconColor);
}

const _kPlatforms = [
  _Platform('youtube',   'YouTube',   Color(0xFFFF0000), Colors.white),
  _Platform('instagram', 'Instagram', Color(0xFFE1306C), Colors.white),
  _Platform('facebook',  'Facebook',  Color(0xFF1877F2), Colors.white),
  _Platform('tiktok',    'TikTok',    Color(0xFF1A1A1A), Colors.white),
];

const _kEngagementRates = ['<1%', '1–3%', '3–6%', '6–10%', '10–20%', '>20%'];

const _kContentTypes = [
  'Short-Form Videos (Reels/Shorts)',
  'Stories',
  'Long-Form Videos',
  'Static Posts',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CreatorSocialMediaScreen extends ConsumerStatefulWidget {
  const CreatorSocialMediaScreen({super.key});

  @override
  ConsumerState<CreatorSocialMediaScreen> createState() =>
      _CreatorSocialMediaScreenState();
}

class _CreatorSocialMediaScreenState
    extends ConsumerState<CreatorSocialMediaScreen> {
  final _followersController = TextEditingController();
  final _urlController = TextEditingController();

  final Set<String> _connected = {};
  String? _engagementRate;
  final Set<String> _contentTypes = {};
  final List<String> _sampleUrls = [];

  bool get _canProceed => _connected.isNotEmpty;

  @override
  void dispose() {
    _followersController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _togglePlatform(String id) =>
      setState(() => _connected.contains(id) ? _connected.remove(id) : _connected.add(id));

  void _addUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty || _sampleUrls.length >= 5) return;
    setState(() {
      _sampleUrls.add(url);
      _urlController.clear();
    });
  }

  void _proceed() {
    ref.read(creatorFormProvider.notifier).saveStep2(
          connectedPlatforms: _connected,
          totalFollowers: _followersController.text.trim(),
          engagementRate: _engagementRate ?? '',
          contentTypes: _contentTypes,
          sampleUrls: List.from(_sampleUrls),
        );
    context.push(RouteNames.creatorApplyReview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _appBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16, DesignTokens.s20, DesignTokens.s16, DesignTokens.s32),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Social Media Profiles', style: DesignTokens.sectionInnerTitle),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Connect at least one social media profile to help us verify your creator status',
                  style: DesignTokens.smallDescription,
                ),
                const SizedBox(height: DesignTokens.s24),

                // Connect platforms
                const Text('Connect Social Media Profile', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Click a social media icon below to connect your account. At least one is required',
                  style: DesignTokens.smallDescription,
                ),
                const SizedBox(height: DesignTokens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _kPlatforms.map((p) => _PlatformIcon(
                    platform: p,
                    connected: _connected.contains(p.id),
                    onTap: () => _togglePlatform(p.id),
                  )).toList(),
                ),
                const SizedBox(height: DesignTokens.s24),

                // Audience Metrics
                const Text('Audience Metrics', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s12),
                TextFormField(
                  controller: _followersController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    color: DesignTokens.inputFieldData,
                  ),
                  cursorColor: DesignTokens.primaryGreen,
                  decoration: DesignTokens.inputDecoration(
                      hintText: 'Total Followers/Subscribers'),
                ),
                const SizedBox(height: DesignTokens.s12),
                _EngagementDropdown(
                  value: _engagementRate,
                  onChanged: (v) => setState(() => _engagementRate = v),
                ),
                const SizedBox(height: DesignTokens.s24),

                // Content Type
                const Text('Content Type', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s12),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: _kContentTypes.map((type) {
                    final sel = _contentTypes.contains(type);
                    return _ToggleChip(
                      label: type,
                      selected: sel,
                      onTap: () => setState(() =>
                          sel ? _contentTypes.remove(type) : _contentTypes.add(type)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.s24),

                // Sample Content
                const Text('Sample Content (Optional)', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text('Share 3-5 of your best performing posts',
                    style: DesignTokens.smallDescription),
                const SizedBox(height: DesignTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        cursorColor: DesignTokens.primaryGreen,
                        decoration: DesignTokens.inputDecoration(hintText: 'Post URL'),
                        onFieldSubmitted: (_) => _addUrl(),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    _IconButton(icon: Icons.add, onTap: _addUrl),
                  ],
                ),
                if (_sampleUrls.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s8),
                  ..._sampleUrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                    child: Row(
                      children: [
                        Expanded(child: _UrlTile(url: e.value)),
                        const SizedBox(width: DesignTokens.s8),
                        _IconButton(
                          icon: Icons.delete_outline,
                          onTap: () => setState(() => _sampleUrls.removeAt(e.key)),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TwoButtonBar(
        onPrevious: () => context.pop(),
        onProceed: _canProceed ? _proceed : null,
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Creator Form', style: DesignTokens.oneLinerSemibold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s12),
            child: _StepBar(currentStep: 1, totalSteps: 3),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Step bar
// ---------------------------------------------------------------------------
class _StepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        Color color;
        if (i < currentStep) {
          color = DesignTokens.primaryGreen;
        } else if (i == currentStep) {
          color = DesignTokens.textWhite;
        } else {
          color = DesignTokens.textWhite.withOpacity(0.25);
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Platform icon with connected badge
// ---------------------------------------------------------------------------
class _PlatformIcon extends StatelessWidget {
  final _Platform platform;
  final bool connected;
  final VoidCallback onTap;
  const _PlatformIcon({
    required this.platform,
    required this.connected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: platform.bgColor,
              boxShadow: connected
                  ? [BoxShadow(
                      color: platform.bgColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )]
                  : null,
            ),
            child: _platformIcon(platform),
          ),
          if (connected)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.primaryGreen,
                  border: Border.all(
                      color: DesignTokens.bgAppFoundation, width: 2),
                ),
                child: const Icon(Icons.check, size: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _platformIcon(_Platform p) {
    switch (p.id) {
      case 'facebook':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SvgPicture.asset('assets/icons/facebook.svg',
              colorFilter: const ColorFilter.mode(
                  Colors.white, BlendMode.srcIn)),
        );
      case 'youtube':
        return const Icon(Icons.play_circle_fill, color: Colors.white, size: 32);
      case 'instagram':
        return const Icon(Icons.camera_alt, color: Colors.white, size: 28);
      case 'tiktok':
        return const Icon(Icons.music_note, color: Colors.white, size: 28);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Engagement dropdown
// ---------------------------------------------------------------------------
class _EngagementDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _EngagementDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesignTokens.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.inputFieldFill,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: DesignTokens.inputFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: DesignTokens.bgAppBody,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: DesignTokens.inputFieldDropdownIcon),
          hint: const Text(
            'Average Engagement Rate',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldPlaceholder,
            ),
          ),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.inputFieldData,
          ),
          onChanged: onChanged,
          items: _kEngagementRates
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle chip (green when selected)
// ---------------------------------------------------------------------------
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          color: selected ? DesignTokens.chipsSelectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: selected
                ? DesignTokens.chipsSelectedBorder
                : DesignTokens.chipsDefaultBorder,
          ),
        ),
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

// ---------------------------------------------------------------------------
// URL list tile
// ---------------------------------------------------------------------------
class _UrlTile extends StatelessWidget {
  final String url;
  const _UrlTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12, vertical: 14),
      decoration: BoxDecoration(
        color: DesignTokens.inputFieldFill,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: DesignTokens.inputFieldBorder),
      ),
      child: Text(
        url,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          color: DesignTokens.inputFieldData,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small square icon button (add / delete)
// ---------------------------------------------------------------------------
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        ),
        child: Icon(icon, color: DesignTokens.textLight, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Two-button bottom bar (Previous + Proceed)
// ---------------------------------------------------------------------------
class _TwoButtonBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback? onProceed;
  const _TwoButtonBar({required this.onPrevious, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _Pill(
                label: 'Previous',
                prefixIcon: Icons.arrow_back_rounded,
                fill: DesignTokens.buttonGrayFill,
                textColor: DesignTokens.textWhite,
                onTap: onPrevious,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Opacity(
                opacity: onProceed != null ? 1.0 : 0.5,
                child: _Pill(
                  label: 'Proceed',
                  suffixIcon: Icons.arrow_forward_rounded,
                  fill: DesignTokens.primaryGreen,
                  textColor: DesignTokens.buttonPrimaryText,
                  onTap: onProceed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color fill;
  final Color textColor;
  final VoidCallback? onTap;
  const _Pill({
    required this.label,
    required this.fill,
    required this.textColor,
    required this.onTap,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: DesignTokens.iconSmall, color: textColor),
                const SizedBox(width: DesignTokens.s6),
              ],
              Text(label,
                  style: DesignTokens.oneLinerSemibold.copyWith(color: textColor)),
              if (suffixIcon != null) ...[
                const SizedBox(width: DesignTokens.s6),
                Icon(suffixIcon, size: DesignTokens.iconSmall, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
