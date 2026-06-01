import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/device_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/devices_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final session = ref.read(sessionControllerProvider);
    _accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (_accountId != null) {
      ref.read(devicesListProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _trustDevice(String deviceId) async {
    if (_accountId == null) return;
    ref.read(deviceActionProvider.notifier).trustDevice(
      accountId: _accountId!,
      deviceId: deviceId,
    );
  }

  Future<void> _untrustDevice(String deviceId) async {
    if (_accountId == null) return;
    ref.read(deviceActionProvider.notifier).untrustDevice(
      accountId: _accountId!,
      deviceId: deviceId,
    );
  }

  Future<void> _revokeDevice(String deviceId) async {
    if (_accountId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Revoke Device',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: const Text(
          'Are you sure you want to revoke this device? It will be signed out.',
          style: TextStyle(color: DesignTokens.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke', style: TextStyle(color: DesignTokens.colorError)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(deviceActionProvider.notifier).revokeDevice(
        accountId: _accountId!,
        deviceId: deviceId,
      );
    }
  }

  void _showRenameDialog(String deviceId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Rename Device',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: TextField(
          controller: controller,
          style: DesignTokens.bodyText,
          decoration: DesignTokens.inputDecoration(hintText: 'Device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(deviceActionProvider.notifier).renameDevice(
                accountId: _accountId!,
                deviceId: deviceId,
                nickname: controller.text.trim(),
              );
            },
            child: const Text('Save', style: TextStyle(color: DesignTokens.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesState = ref.watch(devicesListProvider);
    ref.listen<DeviceActionState>(deviceActionProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: () {
          _load();
          SmSnackbar.success(context, 'Done');
        },
        loadFailure: (_) => SmSnackbar.error(context, 'Action failed'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Devices',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: devicesState.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (devices) {
            if (devices.isEmpty) {
              return const Center(
                child: Text('No devices registered',
                    style: TextStyle(color: DesignTokens.textMuted)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _DeviceTile(
                  device: device,
                  onTrust: () => _trustDevice(device.id),
                  onUntrust: () => _untrustDevice(device.id),
                  onRevoke: () => _revokeDevice(device.id),
                  onRename: () => _showRenameDialog(
                      device.id, device.nickname ?? ''),
                );
              },
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load devices', style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: _load,
                  child: Text('Retry',
                      style: TextStyle(color: DesignTokens.primaryGreen)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

class _DeviceTile extends StatelessWidget {
  final DeviceDto device;
  final VoidCallback onTrust;
  final VoidCallback onUntrust;
  final VoidCallback onRevoke;
  final VoidCallback onRename;

  const _DeviceTile({
    required this.device,
    required this.onTrust,
    required this.onUntrust,
    required this.onRevoke,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final isRevoked = device.revokedUtc != null;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: isRevoked ? DesignTokens.colorError : DesignTokens.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.nickname ?? device.model ?? 'Unknown Device',
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              if (isRevoked)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
                  decoration: BoxDecoration(
                    color: DesignTokens.colorError.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                  ),
                  child: Text('Revoked',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.colorError)),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          if (device.platform != null || device.osVersion != null)
            Text(
              '${device.platform ?? ''} ${device.osVersion ?? ''}'.trim(),
              style: DesignTokens.smallRegular,
            ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Last active: ${device.lastSeenUtc?.toLocal().toString().split('.')[0] ?? 'Unknown'}',
            style: DesignTokens.tiny,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Trust: ${device.trustLevel ?? 'Unknown'}',
            style: DesignTokens.tiny,
          ),
          if (!isRevoked) ...[
            const SizedBox(height: DesignTokens.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onRename,
                  child: Text('Rename',
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.primaryGreen)),
                ),
                const SizedBox(width: DesignTokens.s16),
                GestureDetector(
                  onTap: onUntrust,
                  child: Text('Untrust',
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.secondaryYellow)),
                ),
                const SizedBox(width: DesignTokens.s16),
                GestureDetector(
                  onTap: onTrust,
                  child: Text('Trust',
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.primaryGreen)),
                ),
                const SizedBox(width: DesignTokens.s16),
                GestureDetector(
                  onTap: onRevoke,
                  child: Text('Revoke',
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.colorError)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
