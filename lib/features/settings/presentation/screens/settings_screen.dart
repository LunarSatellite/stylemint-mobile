import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: DesignTokens.s24),
        children: [
          const SizedBox(height: DesignTokens.s16),

          _SectionHeader(label: 'Account'),
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () => context.push('${RouteNames.profile}/edit'),
          ),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push('${RouteNames.settings}/change-password'),
          ),

          const SizedBox(height: DesignTokens.s16),
          _SectionHeader(label: 'Preferences'),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push('${RouteNames.settings}/notifications'),
          ),
          _MenuTile(
            icon: Icons.language_outlined,
            label: 'Language',
            onTap: () => context.push('${RouteNames.settings}/language'),
          ),

          const SizedBox(height: DesignTokens.s16),
          _SectionHeader(label: 'About'),
          _MenuTile(
            icon: Icons.shield_outlined,
            label: 'Privacy Policy',
            onTap: () => context.push('${RouteNames.settings}/privacy'),
          ),
          _MenuTile(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () => context.push('${RouteNames.settings}/terms'),
          ),
          _MenuTile(
            icon: Icons.info_outline,
            label: 'About ReelCommerce',
            onTap: () => context.push(RouteNames.settingsAbout),
          ),

          const SizedBox(height: DesignTokens.s24),
          _SectionHeader(label: 'Danger Zone'),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            isDestructive: true,
            onTap: () => _confirmLogout(context),
          ),
          _MenuTile(
            icon: Icons.delete_forever_outlined,
            label: 'Delete Account',
            isDestructive: true,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Log Out', style: TextStyle(color: DesignTokens.textWhite)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: DesignTokens.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Delete Account', style: TextStyle(color: DesignTokens.colorError)),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.', style: TextStyle(color: DesignTokens.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s8),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? DesignTokens.colorError : DesignTokens.textWhite;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: 2),
      child: Material(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: DesignTokens.iconMedium),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(label, style: DesignTokens.mediumRegular.copyWith(color: color)),
                ),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: DesignTokens.s8),
                ],
                if (!isDestructive)
                  const Icon(Icons.chevron_right_rounded, color: DesignTokens.iconLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
