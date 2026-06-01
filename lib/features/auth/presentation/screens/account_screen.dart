import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _account;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  String? get _accountId {
    final session =
        ref.read(sessionControllerProvider);
    return session.maybeWhen(authenticated: (id) => id, orElse: () => null);
  }

  Future<void> _loadAccount() async {
    final id = _accountId;
    if (id == null) return;

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getAccount(id);

    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _isLoading = false;
        _error = 'Failed to load account';
      }),
      (account) => setState(() {
        _isLoading = false;
        _account = {
          'displayName': account.displayName ?? '—',
          'email': account.id,
          'locale': account.locale ?? '—',
          'timezone': account.timezone ?? '—',
          'status': account.status ?? 'Active',
          'countryCode': account.countryCode ?? '—',
          'createdUtc': account.createdUtc.toString(),
          'rowVersion': account.rowVersion,
        };
      }),
    );
  }

  Future<void> _handlePause() async {
    final days = await showDialog<int>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: DesignTokens.bgAppBody,
            title: Text(
              'Pause Account',
              style: DesignTokens.sectionInnerTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [7, 14, 30].map((d) {
                return ListTile(
                  title: Text(
                    '$d days',
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, d),
                );
              }).toList(),
            ),
          ),
    );

    if (days == null || _accountId == null) return;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.pause(days: days);

    if (!mounted) return;
    result.fold(
      (f) => SmSnackbar.error(context, 'Failed to pause account'),
      (_) {
        SmSnackbar.success(context, 'Account paused for $days days');
        _loadAccount();
      },
    );
  }

  Future<void> _handleResume() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.resume();

    if (!mounted) return;
    result.fold(
      (f) => SmSnackbar.error(context, 'Failed to resume account'),
      (_) {
        SmSnackbar.success(context, 'Account resumed');
        _loadAccount();
      },
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: DesignTokens.bgAppBody,
            title: Text(
              'Delete Account',
              style: DesignTokens.sectionInnerTitle,
            ),
            content: Text(
              'This action is permanent and cannot be undone. '
              'All your data will be permanently deleted.',
              style: DesignTokens.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || _accountId == null) return;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.deleteAccount(
      _accountId!,
      const Uuid().v4(),
    );

    if (!mounted) return;
    result.fold(
      (f) => SmSnackbar.error(context, 'Failed to delete account'),
      (_) {
        SmSnackbar.success(context, 'Account deletion requested');
        ref.read(sessionControllerProvider.notifier).logout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: DesignTokens.textWhite,
            size: DesignTokens.iconMedium,
          ),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Text('Account', style: DesignTokens.sectionInnerTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: DesignTokens.bodyText))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_account == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.appHorizontalPadding,
        vertical: DesignTokens.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection('Profile', [
            _infoRow('Display Name', _account!['displayName'] as String),
            _infoRow('Country', _account!['countryCode'] as String),
            _infoRow('Status', _account!['status'] as String),
          ]),
          const SizedBox(height: DesignTokens.s16),
          _buildSection('Settings', [
            _infoRow('Locale', _account!['locale'] as String),
            _infoRow('Timezone', _account!['timezone'] as String),
          ]),
          const SizedBox(height: DesignTokens.s24),

          _buildMenuTile(
            icon: Icons.password_rounded,
            title: 'Change Password',
            onTap: () => context.push(RouteNames.settingsChangePassword),
          ),
          _buildMenuTile(
            icon: Icons.devices_rounded,
            title: 'Sessions',
            onTap: () => context.push(RouteNames.sessions),
          ),
          const Divider(
            color: DesignTokens.borderDefault,
            height: DesignTokens.s32,
          ),

          SizedBox(
            height: DesignTokens.buttonHeight,
            child: SmPrimaryButton(
              label: 'Pause Account',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.secondaryYellow,
              labelColor: DesignTokens.textDark,
              onPressed: _handlePause,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            height: DesignTokens.buttonHeight,
            child: SmPrimaryButton(
              label: 'Resume Account',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              onPressed: _handleResume,
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          SizedBox(
            height: DesignTokens.buttonHeight,
            child: SmPrimaryButton(
              label: 'Delete Account',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.colorError,
              labelColor: DesignTokens.textWhite,
              onPressed: _handleDelete,
            ),
          ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s8),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DesignTokens.mediumRegular),
          Text(
            value,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        child: Row(
          children: [
            Icon(icon, color: DesignTokens.textLight, size: DesignTokens.iconSmall),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(title, style: DesignTokens.mediumRegular),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.textMuted,
              size: DesignTokens.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}
