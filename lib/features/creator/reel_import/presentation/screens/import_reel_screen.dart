import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportReelScreen extends ConsumerStatefulWidget {
  const ImportReelScreen({super.key});

  @override
  ConsumerState<ImportReelScreen> createState() => _ImportReelScreenState();
}

class _ImportReelScreenState extends ConsumerState<ImportReelScreen> {
  SocialPlatform _selectedPlatform = SocialPlatform.instagram;
  final _urlController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String get _url => _urlController.text.trim();

  List<String> _howToSteps(SocialPlatform platform) => [
        'Open your reel on ${platform.displayName}',
        'Tap the share button',
        "Select 'Copy Link'",
        'Paste it above',
      ];

  Future<void> _import() async {
    if (_url.isEmpty) return;
    setState(() => _isImporting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isImporting = false);
    context.push(
      RouteNames.reelImportPreview,
      extra: {'url': _url, 'platform': _selectedPlatform},
    );
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved as draft')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Import Reel', style: DesignTokens.titleMedium),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Description ─────────────────────────────────────────
                  Text(
                    "Paste the link to your post from Instagram, TikTok or"
                    " Youtube Shorts. We'll import it automatically",
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // ── Select Platform ──────────────────────────────────────
                  const Text(
                    'Select Platform',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  Row(
                    children: SocialPlatform.values.map((platform) {
                      final isLast =
                          platform == SocialPlatform.values.last;
                      return Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(right: isLast ? 0 : DesignTokens.s8),
                          child: _PlatformTile(
                            platform: platform,
                            isSelected: platform == _selectedPlatform,
                            onTap: () =>
                                setState(() => _selectedPlatform = platform),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // ── URL input ────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBody,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.s12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textWhite,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste Reel URL',
                              hintStyle: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: DesignTokens.s12,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        const Icon(
                          Icons.link_rounded,
                          color: DesignTokens.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // ── How to get the link ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2D3A),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.s12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to get the link ?',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4DD8C0),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s12),
                        for (final step in _howToSteps(_selectedPlatform))
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: DesignTokens.s8),
                            child: _BulletRow(text: step),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),

                  // ── Supported URL Formats ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2B0D),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.s12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Supported URL Formats',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD4C84A),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s12),
                        for (final fmt in const [
                          'instagram.com/reel/[ID]',
                          'instagram.com/p/[ID]',
                          'tiktok.com/@user/video/[ID]',
                          'youtube.com/shorts/[ID]',
                        ])
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: DesignTokens.s8),
                            child: _BulletRow(text: fmt),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s32),
                ],
              ),
            ),
          ),

          // ── Sticky bottom buttons ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppFoundation,
              border: Border(
                top: BorderSide(color: DesignTokens.borderDefault),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _saveAsDraft,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        foregroundColor: DesignTokens.textWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                        ),
                      ),
                      child: const Text(
                        'Save as Draft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed:
                          _url.isNotEmpty && !_isImporting ? _import : null,
                      style: DesignTokens.primaryButtonStyle().copyWith(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: DesignTokens.s12),
                        ),
                      ),
                      child: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Flexible(
                                  child: Text(
                                    'Import Reel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.download_rounded, size: 18),
                              ],
                            ),
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

// ── Platform tile ─────────────────────────────────────────────────────────────

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.platform,
    required this.isSelected,
    required this.onTap,
  });

  final SocialPlatform platform;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.primaryGreen
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _iconWidget(),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  platform.displayName,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconWidget() {
    switch (platform) {
      case SocialPlatform.instagram:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 20,
          ),
        );
      case SocialPlatform.youtube:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 24,
          ),
        );
      case SocialPlatform.tiktok:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF010101),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 20,
          ),
        );
      case SocialPlatform.facebook:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
            ),
          ),
        );
    }
  }
}

// ── Bullet row ────────────────────────────────────────────────────────────────

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(color: DesignTokens.textLight, fontSize: 13),
        ),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
