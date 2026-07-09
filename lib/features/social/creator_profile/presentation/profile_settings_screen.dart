import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/logout_action.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    super.key,
  });

  final String displayName;
  final String handle;
  final String? avatarUrl;

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  XFile? _pickedImage;

  @override
  Widget build(BuildContext context) {
    final accountId = ref.watch(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => '',
    );

    final profile = ref
        .watch(creatorProfileNotifierProvider(accountId))
        .maybeWhen(loadSuccess: (p) => p, orElse: () => null);

    final displayName = profile?.displayName ?? widget.displayName;
    final handle = profile?.handle ?? widget.handle;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s24),
        child: Column(
          children: [
            _AvatarSection(
              avatarUrl: widget.avatarUrl,
              pickedImage: _pickedImage,
              onImagePicked: (file) {
                setState(() => _pickedImage = file);
                ref.read(avatarImagePathProvider.notifier).setPath(file.path);
              },
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            _BecomeBrandBanner(),
            const SizedBox(height: DesignTokens.s20),
            _MenuGroup(
              items: [
                _MenuItem(
                  icon: Icons.workspace_premium_outlined,
                  iconWidget: Image.asset(
                    'assets/images/creatordash/crowned.png',
                    width: 20,
                    height: 20,
                  ),
                  label: 'Upgrade Subscription Plan',
                  onTap: () => context.push(
                      RouteNames.creatorUpgradeSubscription),
                ),
                _MenuItem(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Edit Profile Details',
                  onTap: () => context.push(
                    RouteNames.creatorEditProfile,
                    extra: CreatorProfileArgs(
                      accountId: accountId,
                      displayName: displayName,
                      handle: handle,
                    ),
                  ),
                ),
                _MenuItem(
                  icon: Icons.local_police_outlined,
                  label: 'Badges',
                  onTap: () => context.push(RouteNames.creatorProfileBadges),
                ),
                _MenuItem(
                  icon: Icons.category_outlined,
                  label: 'Category Niche',
                  onTap: () =>
                      context.push(RouteNames.creatorCategoryNiche),
                ),
                _MenuItem(
                  icon: Icons.key_outlined,
                  label: 'Change Password',
                  onTap: () => context.push(RouteNames.settingsChangePassword),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            _MenuGroup(
              items: [
                _MenuItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Contact Support',
                  onTap: () => context.push(RouteNames.creatorSupportContact),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  onTap: () => confirmAndLogout(context, ref),
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar with edit pencil ───────────────────────────────────────────────────

void _showAvatarPickerSheet(
    BuildContext context, ValueChanged<XFile> onImagePicked) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _AvatarPickerSheet(onImagePicked: onImagePicked),
  );
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    this.avatarUrl,
    this.pickedImage,
    required this.onImagePicked,
  });
  final String? avatarUrl;
  final XFile? pickedImage;
  final ValueChanged<XFile> onImagePicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAvatarPickerSheet(context, onImagePicked),
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 88,
              height: 88,
              child: pickedImage != null
                  ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                  : (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? Image.network(avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, _e) => _placeholder())
                      : _placeholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showAvatarPickerSheet(context, onImagePicked),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: DesignTokens.bgAppFoundation, width: 2),
                ),
                child: const Icon(Icons.edit,
                    size: 13, color: DesignTokens.textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(Icons.person,
            size: 40, color: DesignTokens.iconLight),
      );
}

// ── Avatar picker bottom sheet ────────────────────────────────────────────────

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({required this.onImagePicked});
  final ValueChanged<XFile> onImagePicked;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file != null) onImagePicked(file);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            DesignTokens.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _PickerOption(
            icon: Icons.image_outlined,
            label: 'Upload from photos',
            onTap: () => _pick(context, ImageSource.gallery),
          ),
          const Divider(
              height: 1, thickness: 1, color: DesignTokens.borderDefault),
          _PickerOption(
            icon: Icons.camera_alt_outlined,
            label: 'Take a picture',
            onTap: () => _pick(context, ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: DesignTokens.textLight),
            const SizedBox(width: DesignTokens.s16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 15,
                  color: DesignTokens.textLight,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: DesignTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Become a Brand banner ─────────────────────────────────────────────────────

class _BecomeBrandBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5C32), Color(0xFF1DB954), Color(0xFF25E07A)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Become a Brand !',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Become a Brand User and start selling your products',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 11,
                      color: DesignTokens.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/images/creatordash/shop.png',
            width: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, _e) => const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.storefront_rounded,
                  color: DesignTokens.primaryGreen, size: 48),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: DesignTokens.s12),
            child: Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textWhite, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Menu components ───────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconWidget,
    this.destructive = false,
  });
  final IconData icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: DesignTokens.borderDefault,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.destructive ? DesignTokens.colorError : DesignTokens.textLight;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s16),
        child: Row(
          children: [
            item.iconWidget ?? Icon(item.icon, size: 20, color: color),
            const SizedBox(width: DesignTokens.s16),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textMuted),
          ],
        ),
      ),
    );
  }
}
