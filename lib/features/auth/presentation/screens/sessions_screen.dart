import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/user_session_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:intl/intl.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  List<UserSessionDto> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final session =
        ref.read(sessionControllerProvider);
    final accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => '',
    );

    if (accountId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.listSessions(accountId);
    if (!mounted) return;

    result.fold(
      (f) => setState(() {
        _isLoading = false;
        _error = 'Failed to load sessions';
      }),
      (sessions) => setState(() {
        _isLoading = false;
        _sessions = sessions;
      }),
    );
  }

  Future<void> _revokeSession(UserSessionDto s) async {
    final sessionState =
        ref.read(sessionControllerProvider);
    final accountId = sessionState.maybeWhen(
      authenticated: (id) => id,
      orElse: () => '',
    );

    if (accountId.isEmpty) return;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.revokeSession(
      accountId: accountId,
      sessionId: s.id,
    );

    result.fold(
      (f) => SmSnackbar.error(context, 'Failed to revoke session'),
      (_) {
        setState(() => _sessions.removeWhere((e) => e.id == s.id));
        SmSnackbar.success(context, 'Session revoked');
      },
    );
  }

  Future<void> _revokeAllOthers() async {
    final sessionState =
        ref.read(sessionControllerProvider);
    final accountId = sessionState.maybeWhen(
      authenticated: (id) => id,
      orElse: () => '',
    );

    if (accountId.isEmpty) return;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.revokeAllSessions(accountId);

    result.fold(
      (f) => SmSnackbar.error(context, 'Failed to revoke sessions'),
      (count) {
        _loadSessions();
        SmSnackbar.success(context, '$count session(s) revoked');
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy HH:mm').format(dt.toLocal());
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
        title: Text('Sessions', style: DesignTokens.sectionInnerTitle),
        actions: [
          TextButton(
            onPressed: _revokeAllOthers,
            child: Text(
              'Revoke All',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: DesignTokens.bodyText),
      );
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          'No active sessions',
          style: DesignTokens.bodyText,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.appHorizontalPadding,
          vertical: DesignTokens.s16,
        ),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
        itemBuilder: (context, index) {
          final s = _sessions[index];
          final isActive = s.status == 'Active';
          return Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? DesignTokens.primaryGreen.withOpacity(0.15)
                        : DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                  ),
                  child: Icon(
                    isActive ? Icons.phone_android_rounded : Icons.phone_android_rounded,
                    color: isActive
                        ? DesignTokens.primaryGreen
                        : DesignTokens.textMuted,
                    size: DesignTokens.iconSmall,
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.userAgent ?? 'Unknown Device',
                            style: DesignTokens.mediumSemibold,
                          ),
                          const SizedBox(width: DesignTokens.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? DesignTokens.primaryGreen.withOpacity(0.15)
                                  : DesignTokens.bgAppBodyLight,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.chipRadius,
                              ),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: DesignTokens.tiny.copyWith(
                                color: isActive
                                    ? DesignTokens.primaryGreen
                                    : DesignTokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        'IP: ${s.ipAddress ?? 'N/A'}  |  ${_formatDate(s.lastActivityUtc)}',
                        style: DesignTokens.smallDescription,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: DesignTokens.colorError,
                      size: DesignTokens.iconSmall,
                    ),
                    onPressed: () => _revokeSession(s),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
