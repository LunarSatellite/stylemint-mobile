import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends ConsumerState<NotificationPrefsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _orderUpdates = true;
  bool _promotional = true;
  bool _reelLikes = false;
  bool _newFollowers = false;
  bool _quietHoursEnabled = false;
  TimeOfDay? _quietStart;
  TimeOfDay? _quietEnd;
  bool _loaded = false;

  void _populate(NotificationPreferences prefs) {
    if (_loaded) return;
    _loaded = true;
    _pushEnabled = prefs.pushEnabled;
    _emailEnabled = prefs.emailEnabled;
    _orderUpdates = prefs.orderUpdates;
    _promotional = prefs.promotional;
    _reelLikes = prefs.reelLikes;
    _newFollowers = prefs.newFollowers;
    _quietHoursEnabled = prefs.quietHoursEnabled;
    if (prefs.quietHoursStart != null) {
      final parts = prefs.quietHoursStart!.split(':');
      _quietStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (prefs.quietHoursEnd != null) {
      final parts = prefs.quietHoursEnd!.split(':');
      _quietEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  void _save() {
    ref.read(settingsNotifierProvider.notifier).savePrefs(
      NotificationPreferences(
        pushEnabled: _pushEnabled,
        emailEnabled: _emailEnabled,
        orderUpdates: _orderUpdates,
        promotional: _promotional,
        reelLikes: _reelLikes,
        newFollowers: _newFollowers,
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietStart != null
            ? '${_quietStart!.hour.toString().padLeft(2, '0')}:${_quietStart!.minute.toString().padLeft(2, '0')}'
            : null,
        quietHoursEnd: _quietEnd != null
            ? '${_quietEnd!.hour.toString().padLeft(2, '0')}:${_quietEnd!.minute.toString().padLeft(2, '0')}'
            : null,
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietStart ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (time != null) setState(() => _quietStart = time);
  }

  Future<void> _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietEnd ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) setState(() => _quietEnd = time);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);

    ref.listen<NotificationPrefsState>(settingsNotifierProvider, (prev, next) {
      next.whenOrNull(
        saveSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences saved')),
          );
          context.pop();
        },
        saveFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: ${failure.toString()}')),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.maybeWhen(
        loadSuccess: (prefs) {
          _populate(prefs);
          return _buildBody();
        },
        orElse: () => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.s12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications', style: DesignTokens.mediumRegular),
                      subtitle: const Text('Receive push notifications', style: DesignTokens.smallRegular),
                      value: _pushEnabled,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                    SwitchListTile(
                      title: const Text('Email Notifications', style: DesignTokens.mediumRegular),
                      subtitle: const Text('Receive email updates', style: DesignTokens.smallRegular),
                      value: _emailEnabled,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _emailEnabled = v),
                    ),
                    const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                    SwitchListTile(
                      title: const Text('Order Updates', style: DesignTokens.mediumRegular),
                      subtitle: const Text('Notifications about your orders', style: DesignTokens.smallRegular),
                      value: _orderUpdates,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _orderUpdates = v),
                    ),
                    const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                    SwitchListTile(
                      title: const Text('Promotional', style: DesignTokens.mediumRegular),
                      subtitle: const Text('Deals, offers, and recommendations', style: DesignTokens.smallRegular),
                      value: _promotional,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _promotional = v),
                    ),
                    const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                    SwitchListTile(
                      title: const Text('Reel Likes', style: DesignTokens.mediumRegular),
                      subtitle: const Text('When someone likes your reel', style: DesignTokens.smallRegular),
                      value: _reelLikes,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _reelLikes = v),
                    ),
                    const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                    SwitchListTile(
                      title: const Text('New Followers', style: DesignTokens.mediumRegular),
                      subtitle: const Text('When someone follows you', style: DesignTokens.smallRegular),
                      value: _newFollowers,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _newFollowers = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.s24),

              // Quiet Hours section
              Container(
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.s12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Quiet Hours', style: DesignTokens.mediumRegular),
                      subtitle: const Text('Mute notifications during specific hours', style: DesignTokens.smallRegular),
                      value: _quietHoursEnabled,
                      activeColor: DesignTokens.primaryGreen,
                      onChanged: (v) => setState(() => _quietHoursEnabled = v),
                    ),
                    if (_quietHoursEnabled) ...[
                      const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                      ListTile(
                        title: const Text('Start Time', style: DesignTokens.mediumRegular),
                        trailing: TextButton(
                          onPressed: _pickStartTime,
                          child: Text(
                            _quietStart?.format(context) ?? '22:00',
                            style: const TextStyle(color: DesignTokens.primaryGreen),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: DesignTokens.borderDefault, indent: DesignTokens.s48),
                      ListTile(
                        title: const Text('End Time', style: DesignTokens.mediumRegular),
                        trailing: TextButton(
                          onPressed: _pickEndTime,
                          child: Text(
                            _quietEnd?.format(context) ?? '08:00',
                            style: const TextStyle(color: DesignTokens.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Save button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _save,
                style: DesignTokens.primaryButtonStyle(),
                child: const Text(
                  'Save Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
