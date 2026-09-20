import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Notification settings.
///
/// Every switch on this screen maps to exactly one column the backend stores
/// and reads. Controls that could not do that were removed rather than left
/// on screen lying:
///
///   * **Login Alerts / Password Changes** — `UpdateNotificationTogglesVm` has
///     no Security field, and `IsEmailEnabled`/`IsPushEnabled` return `true`
///     for `NotificationCategory.Security` before consulting any column.
///     Security alerts are transactional and cannot be silenced; the section
///     now says so instead of offering a switch that does nothing.
///   * **Price Drops / Back in Stock / Flash Sales / New Arrivals /
///     Product Recommendations / Personalized Offers** — six switches over one
///     `PushMarketing` column, OR-ed on save. Any one turned off was undone by
///     its siblings and read back on as soon as the screen reloaded. They are
///     now the single "Deals and offers" switch that column can actually back.
///   * **Return Status** — wrote the Messages rollup, which gates partnership
///     invites. Refund and return notifications are `OrderRefunded`, which
///     rolls up to OrderUpdates and is already governed by Order Updates.
class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState
    extends ConsumerState<NotificationPrefsScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Whatever the server holds wins over the entity defaults, on this load
    // and on every later one — a reinstall must not show a local default
    // dressed up as the customer's own choice.
    _adopt(ref.read(settingsNotifierProvider));
  }

  void _adopt(NotificationPrefsState state) {
    state.whenOrNull(
      loadSuccess: (prefs) {
        _loaded = true;
        _prefs = prefs;
      },
    );
  }

  /// Moves the switch, saves, and puts it back if the save did not land.
  ///
  /// A switch left showing the value the customer chose after the write
  /// failed is the same lie in a smaller window: the screen says off, the
  /// server still says on, and the next notification proves it.
  Future<void> _apply(NotificationPreferences next) async {
    final previous = _prefs;
    setState(() => _prefs = next);
    await ref.read(settingsNotifierProvider.notifier).savePrefs(next);
    _revertIfSaveFailed(previous);
  }

  Future<void> _applyQuietHours(NotificationPreferences next) async {
    final previous = _prefs;
    setState(() => _prefs = next);
    await ref.read(settingsNotifierProvider.notifier).saveQuietHours(next);
    _revertIfSaveFailed(previous);
  }

  void _revertIfSaveFailed(NotificationPreferences previous) {
    if (!mounted) return;
    final failed = ref
        .read(settingsNotifierProvider)
        .maybeWhen(saveFailure: (_) => true, orElse: () => false);
    if (failed) setState(() => _prefs = previous);
  }

  void _turnOnAll() {
    // Quiet Hours is a suppression switch (it pauses notifications inside the
    // window when ON) — turning it on here would silently mute the very
    // notifications this button promises to enable.
    final next = _prefs.copyWith(
      pushEnabled: true,
      emailNotifications: true,
      smsNotifications: true,
      orderStatusChanges: true,
      deliveryUpdates: true,
      newReelsFromCreators: true,
      newFollowers: true,
      paymentUpdates: true,
      marketingPush: true,
      newsletter: true,
      quietHoursEnabled: false,
    );
    final previous = _prefs;
    setState(() => _prefs = next);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    unawaited(
      notifier
          .savePrefs(next)
          .then((_) => notifier.saveQuietHours(next))
          .then((_) => _revertIfSaveFailed(previous)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationPrefsState>(settingsNotifierProvider, (_, next) {
      next.whenOrNull(
        loadSuccess: (prefs) {
          if (_loaded && prefs == _prefs) return;
          setState(() {
            _loaded = true;
            _prefs = prefs;
          });
        },
        saveFailure: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save preferences. Please try again.'),
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: const Text(
          'Notification Settings',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                const _SectionLabel('Push Notifications'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.notifications_active_outlined,
                      title: 'Enable Push Notifications',
                      subtitle:
                          'Allow StyleMint to send you push notifications',
                      value: _prefs.pushEnabled,
                      onChanged: (v) => _apply(_prefs.copyWith(pushEnabled: v)),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Order Updates'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Order Updates',
                      subtitle:
                          'Order placed, cancelled and refunded, including '
                          'return refunds',
                      value: _prefs.orderStatusChanges,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(orderStatusChanges: v)),
                    ),
                    _ToggleItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Delivery Updates',
                      subtitle: 'Shipped and delivered',
                      value: _prefs.deliveryUpdates,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(deliveryUpdates: v)),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Creator Activity'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.play_circle_outline,
                      title: 'Reel Activity',
                      subtitle:
                          'New reels from creators you follow, and replies to '
                          'your comments',
                      value: _prefs.newReelsFromCreators,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(newReelsFromCreators: v)),
                    ),
                    _ToggleItem(
                      icon: Icons.person_add_alt_outlined,
                      title: 'New Followers',
                      subtitle: 'When someone follows you',
                      value: _prefs.newFollowers,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(newFollowers: v)),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Account & Security'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.campaign_outlined,
                      title: 'Account Announcements',
                      subtitle:
                          'Payments and payouts, support replies and service '
                          'notices',
                      value: _prefs.paymentUpdates,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(paymentUpdates: v)),
                    ),
                  ],
                ),
                const _FootNote(
                  icon: Icons.lock_outline,
                  text:
                      'Security alerts — new sign-ins and password changes — '
                      'are always sent and cannot be turned off.',
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Deals & Marketing'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.local_offer_outlined,
                      title: 'Deals and offers',
                      subtitle:
                          'Price drops, back in stock, sales and reminders, '
                          'as push notifications',
                      value: _prefs.marketingPush,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(marketingPush: v)),
                    ),
                    _ToggleItem(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Marketing email',
                      subtitle: 'Deals, new products and tips, by email',
                      value: _prefs.newsletter,
                      onChanged: (v) => _apply(_prefs.copyWith(newsletter: v)),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Email & SMS'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Notifications & Alerts to your email',
                      value: _prefs.emailNotifications,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(emailNotifications: v)),
                    ),
                    _ToggleItem(
                      icon: Icons.sms_outlined,
                      title: 'SMS Notifications',
                      subtitle: "Notifications & Alerts to your phone's sms",
                      value: _prefs.smsNotifications,
                      onChanged: (v) =>
                          _apply(_prefs.copyWith(smsNotifications: v)),
                    ),
                  ],
                ),
                const _FootNote(
                  icon: Icons.info_outline,
                  text:
                      'SMS is used for security codes only today, so this '
                      'switch will not change what you receive yet.',
                ),
                const SizedBox(height: DesignTokens.s16),

                const _SectionLabel('Quiet Hours'),
                _SectionCard(
                  items: [
                    _ToggleItem(
                      icon: Icons.bedtime_outlined,
                      title: 'Pause Notifications',
                      subtitle:
                          'Pause notifications from '
                          '${_formatTime(_prefs.quietHoursStart ?? '22:00')} – '
                          '${_formatTime(_prefs.quietHoursEnd ?? '08:00')}',
                      value: _prefs.quietHoursEnabled,
                      onChanged: (v) => _applyQuietHours(
                        _prefs.copyWith(quietHoursEnabled: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: DesignTokens.borderDefault,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _turnOnAll,
                  style: DesignTokens.primaryButtonStyle(),
                  child: Text(
                    'Turn On All Notifications',
                    textAlign: TextAlign.center,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Text(
        text,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

// ── Explanatory note (not a control) ─────────────────────────────────────────

class _FootNote extends StatelessWidget {
  const _FootNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s4,
        DesignTokens.s8,
        DesignTokens.s4,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: DesignTokens.textMuted),
          const SizedBox(width: DesignTokens.s6),
          Expanded(
            child: Text(
              text,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items});
  final List<_ToggleItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: DesignTokens.borderDefault,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
              ),
            items[i],
          ],
        ],
      ),
    );
  }
}

// ── Toggle item ──────────────────────────────────────────────────────────────

/// A settings switch. Its state is carried by the glyph and the word "On"/
/// "Off" as well as the switch position, never by colour alone, and the whole
/// row wraps rather than clipping at 320dp with large text.
class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      hint: subtitle,
      toggled: value,
      child: _row(),
    );
  }

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 18,
              color: value ? DesignTokens.primaryGreen : DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      value
                          ? Icons.check_circle_outline
                          : Icons.do_not_disturb_on_outlined,
                      size: 13,
                      color: value
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    Text(
                      value ? 'On' : 'Off',
                      style: DesignTokens.smallRegular.copyWith(
                        color: value
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: DesignTokens.primaryGreen,
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return DesignTokens.primaryGreen.withValues(alpha: 0.3);
              }
              return DesignTokens.bgAppBodyLight;
            }),
          ),
        ],
      ),
    );
  }
}
