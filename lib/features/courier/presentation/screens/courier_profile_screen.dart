import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_balance_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_device_key_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/presentation/screens/referrals_screen.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Everything the app knows about this delivery partner, in one place.
///
/// Assembled from several endpoints rather than one, because a courier is
/// several things to the backend at once: an Identity account (name, email,
/// phone), a DeliveryCouriers profile (state, tier, vehicle, home area,
/// deposit), a reliability snapshot, and a signing key held on this device.
/// Each of those already had a screen or no surface at all; none of them
/// answered "who am I and where do I stand".
class CourierProfileScreen extends ConsumerWidget {
  const CourierProfileScreen({required this.profile, super.key});

  final CourierProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reliability = ref.watch(courierReliabilityProvider(profile.id));
    final earnings = ref.watch(courierEarningsProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(courierReliabilityProvider(profile.id))
              ..invalidate(courierEarningsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s20),
            children: [
              _Identity(profile: profile),

              const SizedBox(height: DesignTokens.s24),
              Text('Standing', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s8),
              _Row(
                label: 'Account',
                value: profile.state.label,
              ),
              _Row(label: 'Tier', value: profile.tier.label),
              _Row(
                label: 'Reliability',
                value: reliability.when(
                  loading: () => '…',
                  // 404 until the first hop is scored, which is not a failure.
                  error: (_, _) => 'No score yet',
                  data: (snapshot) => snapshot == null
                      ? 'No score yet'
                      : '${(snapshot.reliabilityScore * 100).toStringAsFixed(0)}%',
                ),
              ),
              if (profile.failureStreak > 0)
                _Row(
                  label: 'Failed in a row',
                  value: '${profile.failureStreak}',
                  warn: true,
                ),
              if (profile.suspendedReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.s8),
                  child: Text(
                    profile.suspendedReason!,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),

              const SizedBox(height: DesignTokens.s24),
              Text('Work setup', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s8),
              _Row(
                label: 'Vehicle',
                value: profile.vehicle?.label ?? 'Not set',
              ),
              _Row(
                label: 'Home area',
                // The geohash itself, not a decoded address: five characters
                // is a ~5 km cell, which is the granularity the router matches
                // on and not somewhere to pretend a street name exists.
                value: profile.homeGeohash.isEmpty
                    ? 'Not set'
                    : profile.homeGeohash,
              ),
              _Row(
                label: 'Deposit held',
                value: formatMoney(
                  Money(
                    amount: profile.escrowHeldAmount,
                    currency: profile.escrowCurrency,
                  ),
                ),
                warn: profile.escrowShortfall,
              ),
              if (profile.escrowShortfall)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.s4),
                  child: Text(
                    'Below the ${formatMoney(Money(amount: profile.escrowRequiredAmount, currency: profile.escrowCurrency))} '
                    'required for your tier, so offers stop until it is topped up.',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),

              const SizedBox(height: DesignTokens.s24),
              _Entry(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Balance',
                subtitle: earnings.when(
                  loading: () => 'Loading…',
                  error: (_, _) => 'What your deliveries have paid',
                  data: (e) => e.hasEarned
                      ? '${e.completedHops} deliveries completed'
                      : 'No deliveries completed yet',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CourierBalanceScreen(courierProfileId: profile.id),
                  ),
                ),
              ),
              _Entry(
                icon: Icons.key_rounded,
                title: 'Signing key',
                subtitle: 'Proves handovers were made by this device',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CourierDeviceKeyScreen(courierProfileId: profile.id),
                  ),
                ),
              ),
              _Entry(
                icon: Icons.card_giftcard_rounded,
                title: 'Invite a friend',
                subtitle: 'Share your invite link',
                // The app already has a referrals screen built on Identity's
                // invite links, so this points at it rather than growing a
                // second, courier-only invite flow against the same endpoint.
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferralsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final CourierProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.accountDisplayName?.trim();
    final email = profile.accountEmail?.trim();
    final phone = profile.accountPhone?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null || name.isEmpty ? 'Name not set' : name,
              style: DesignTokens.h3,
            ),
            const SizedBox(height: DesignTokens.s4),
            // Shown as gaps rather than hidden: a courier whose email is
            // missing should be able to see that it is missing, because it is
            // how they would be contacted about a delivery.
            Text(
              email == null || email.isEmpty ? 'No email on file' : email,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            Text(
              phone == null || phone.isEmpty ? 'No phone on file' : phone,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            if (profile.kycVerifiedUtc != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: DesignTokens.colorSuccess,
                  ),
                  const SizedBox(width: DesignTokens.s4),
                  Text(
                    'Identity verified',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.colorSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: DesignTokens.mediumSemibold.copyWith(
            color: warn ? DesignTokens.colorError : null,
          ),
        ),
      ],
    ),
  );
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(icon, color: DesignTokens.primaryGreen),
        title: Text(title, style: DesignTokens.mediumSemibold),
        subtitle: Text(
          subtitle,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    ),
  );
}
