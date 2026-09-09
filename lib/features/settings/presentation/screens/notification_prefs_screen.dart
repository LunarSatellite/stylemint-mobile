import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class NotificationPrefsScreen extends ConsumerStatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  ConsumerState<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState
    extends ConsumerState<NotificationPrefsScreen> {
  // Push
  bool _pushEnabled = true;
  // Order Updates
  bool _orderStatusChanges = true;
  bool _deliveryUpdates = true;
  bool _returnStatus = true;
  // Shopping & Deals
  bool _priceDrops = true;
  bool _backInStock = true;
  bool _flashSales = true;
  bool _newArrivals = false;
  // Creator Activity
  bool _newReelsFromCreators = false;
  bool _creatorRecommendations = false;
  // Account & Security
  bool _loginAlerts = true;
  bool _passwordChanges = true;
  bool _paymentUpdates = true;
  // Marketing & Promotions
  bool _personalizedOffers = true;
  bool _productRecommendations = false;
  bool _newsletter = false;
  // Email & SMS
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  // Quiet Hours
  bool _quietHoursEnabled = true;
  String _quietStart = '22:00';
  String _quietEnd = '08:00';

  NotificationPreferences _original = const NotificationPreferences();

  void _saveAll() {
    ref.read(settingsNotifierProvider.notifier).savePrefs(
      _original.copyWith(
        pushEnabled: _pushEnabled,
        orderStatusChanges: _orderStatusChanges,
        deliveryUpdates: _deliveryUpdates,
        returnStatus: _returnStatus,
        priceDrops: _priceDrops,
        backInStock: _backInStock,
        flashSales: _flashSales,
        newArrivals: _newArrivals,
        newReelsFromCreators: _newReelsFromCreators,
        creatorRecommendations: _creatorRecommendations,
        loginAlerts: _loginAlerts,
        passwordChanges: _passwordChanges,
        paymentUpdates: _paymentUpdates,
        personalizedOffers: _personalizedOffers,
        productRecommendations: _productRecommendations,
        newsletter: _newsletter,
        emailNotifications: _emailNotifications,
        smsNotifications: _smsNotifications,
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietStart,
        quietHoursEnd: _quietEnd,
      ),
    );
  }

  void _turnOnAll() {
    setState(() {
      _pushEnabled = true;
      _orderStatusChanges = true;
      _deliveryUpdates = true;
      _returnStatus = true;
      _priceDrops = true;
      _backInStock = true;
      _flashSales = true;
      _newArrivals = true;
      _newReelsFromCreators = true;
      _creatorRecommendations = true;
      _loginAlerts = true;
      _passwordChanges = true;
      _paymentUpdates = true;
      _personalizedOffers = true;
      _productRecommendations = true;
      _newsletter = true;
      _emailNotifications = true;
      _smsNotifications = true;
      _quietHoursEnabled = true;
    });
    _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);

    // Sync local state from provider when prefs are loaded from backend
    state.maybeWhen(
      loadSuccess: (prefs) {
        _original = prefs;
        setState(() {
          _pushEnabled = prefs.pushEnabled;
          _orderStatusChanges = prefs.orderStatusChanges;
          _deliveryUpdates = prefs.deliveryUpdates;
          _returnStatus = prefs.returnStatus;
          _priceDrops = prefs.priceDrops;
          _backInStock = prefs.backInStock;
          _flashSales = prefs.flashSales;
          _newArrivals = prefs.newArrivals;
          _newReelsFromCreators = prefs.newReelsFromCreators;
          _creatorRecommendations = prefs.creatorRecommendations;
          _loginAlerts = prefs.loginAlerts;
          _passwordChanges = prefs.passwordChanges;
          _paymentUpdates = prefs.paymentUpdates;
          _personalizedOffers = prefs.personalizedOffers;
          _productRecommendations = prefs.productRecommendations;
          _newsletter = prefs.newsletter;
          _emailNotifications = prefs.emailNotifications;
          _smsNotifications = prefs.smsNotifications;
          _quietHoursEnabled = prefs.quietHoursEnabled;
          if (prefs.quietHoursStart != null) _quietStart = prefs.quietHoursStart!;
          if (prefs.quietHoursEnd != null) _quietEnd = prefs.quietHoursEnd!;
        });
      },
      orElse: () {},
    );

    ref.listen<NotificationPrefsState>(settingsNotifierProvider, (_, next) {
      next.whenOrNull(
        saveSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
        ),
        saveFailure: (f) => ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text('Notification Settings', style: DesignTokens.sectionInnerTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                // ── Push Notifications ─────────────────────────────────
                _SectionLabel('Push Notifications'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Enable Push Notifications',
                    subtitle: 'Allow StyleMint to send you push notifications',
                    value: _pushEnabled,
                    onChanged: (v) {
                      setState(() => _pushEnabled = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Order Updates ──────────────────────────────────────
                _SectionLabel('Order Updates'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Order Status Changes',
                    subtitle: 'Order shipped, Delivered & Delays',
                    value: _orderStatusChanges,
                    onChanged: (v) {
                      setState(() => _orderStatusChanges = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Delivery Updates',
                    subtitle: 'Out for delivery, Delivery attempts',
                    value: _deliveryUpdates,
                    onChanged: (v) {
                      setState(() => _deliveryUpdates = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Return Status',
                    subtitle: 'Return approved, Refund processed',
                    value: _returnStatus,
                    onChanged: (v) {
                      setState(() => _returnStatus = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Shopping & Deals ───────────────────────────────────
                _SectionLabel('Shopping & Deals'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Price Drops',
                    subtitle: 'When saved items go on sale',
                    value: _priceDrops,
                    onChanged: (v) {
                      setState(() => _priceDrops = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Back in Stock',
                    subtitle: 'Products you want are available',
                    value: _backInStock,
                    onChanged: (v) {
                      setState(() => _backInStock = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Flash Sales',
                    subtitle: 'Limited-time deals and promotions',
                    value: _flashSales,
                    onChanged: (v) {
                      setState(() => _flashSales = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'New Arrivals',
                    subtitle: 'Latest products in categories you follow',
                    value: _newArrivals,
                    onChanged: (v) {
                      setState(() => _newArrivals = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Creator Activity ───────────────────────────────────
                _SectionLabel('Creator Activity'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'New Reels from Creators',
                    subtitle: 'When creators you follow post new reels',
                    value: _newReelsFromCreators,
                    onChanged: (v) {
                      setState(() => _newReelsFromCreators = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Creator Recommendations',
                    subtitle: 'Suggested creators to follow',
                    value: _creatorRecommendations,
                    onChanged: (v) {
                      setState(() => _creatorRecommendations = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Account & Security ─────────────────────────────────
                _SectionLabel('Account & Security'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Login Alerts',
                    subtitle: 'New device or unusual  activity',
                    value: _loginAlerts,
                    onChanged: (v) {
                      setState(() => _loginAlerts = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Password Changes',
                    subtitle: 'Account security updates',
                    value: _passwordChanges,
                    onChanged: (v) {
                      setState(() => _passwordChanges = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Payment Updates',
                    subtitle: 'Payment method changes, receipts',
                    value: _paymentUpdates,
                    onChanged: (v) {
                      setState(() => _paymentUpdates = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Marketing & Promotions ─────────────────────────────
                _SectionLabel('Marketing & Promotions'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Personalized Offers',
                    subtitle: 'Special deals based on your interests',
                    value: _personalizedOffers,
                    onChanged: (v) {
                      setState(() => _personalizedOffers = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Product Recommendations',
                    subtitle: 'Suggested products you might like',
                    value: _productRecommendations,
                    onChanged: (v) {
                      setState(() => _productRecommendations = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'Newsletter',
                    subtitle: 'Weekly email with new products and tips',
                    value: _newsletter,
                    onChanged: (v) {
                      setState(() => _newsletter = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Email & SMS ────────────────────────────────────────
                _SectionLabel('Email & SMS'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Email Notifications',
                    subtitle: 'Notifications & Alerts to your email',
                    value: _emailNotifications,
                    onChanged: (v) {
                      setState(() => _emailNotifications = v);
                      _saveAll();
                    },
                  ),
                  _ToggleItem(
                    title: 'SMS Notifications',
                    subtitle: "Notifications & Alerts to your phone's sms",
                    value: _smsNotifications,
                    onChanged: (v) {
                      setState(() => _smsNotifications = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),

                // ── Quiet Hours ────────────────────────────────────────
                _SectionLabel('Quiet Hours'),
                _SectionCard(items: [
                  _ToggleItem(
                    title: 'Pause Notifications',
                    subtitle:
                        'Pause notifications from ${_formatTime(_quietStart)} – ${_formatTime(_quietEnd)}',
                    value: _quietHoursEnabled,
                    onChanged: (v) {
                      setState(() => _quietHoursEnabled = v);
                      _saveAll();
                    },
                  ),
                ]),
                const SizedBox(height: DesignTokens.s16),
              ],
            ),
          ),

          // ── Pinned button ────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: DesignTokens.borderDefault),
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
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
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

// ── Toggle item ───────────────────────────────────────────────────────────────

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s4,
      ),
      title: Text(
        title,
        style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
      ),
      subtitle: Text(
        subtitle,
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
      ),
      value: value,
      activeColor: DesignTokens.primaryGreen,
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DesignTokens.primaryGreen.withValues(alpha: 0.3);
        }
        return DesignTokens.bgAppBodyLight;
      }),
      onChanged: onChanged,
    );
  }
}

