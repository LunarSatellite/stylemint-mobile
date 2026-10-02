import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Become a delivery partner".
///
/// Asks for one thing the courier has to choose — their vehicle — and takes the
/// home area from the device's location rather than making them type a
/// geohash. The backend validates `homeGeohash` against the base-32 alphabet
/// and a 5–16 length, which is not something to put in front of a person.
class CourierApplyScreen extends ConsumerStatefulWidget {
  const CourierApplyScreen({super.key});

  @override
  ConsumerState<CourierApplyScreen> createState() => _CourierApplyScreenState();
}

class _CourierApplyScreenState extends ConsumerState<CourierApplyScreen> {
  CourierVehicle? _vehicle;

  Future<void> _apply() async {
    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .apply(vehicle: _vehicle);
    if (!mounted) return;

    if (result is CourierActionOk) {
      // The gate re-reads the profile and moves this courier on to KYC. No
      // navigation here: the gate owns which screen a state maps to, and
      // pushing from here would mean two places deciding that.
      ref.invalidate(courierProfileProvider(ref.read(courierAccountIdProvider)));
      return;
    }
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courierActionsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Deliver with StyleMint'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Earn on journeys you already make', style: DesignTokens.h2),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Carry parcels near you, or on trips you have planned. You pick '
                'what you accept — nothing is assigned to you.',
                style: DesignTokens.smallRegular,
              ),
              const SizedBox(height: DesignTokens.s24),

              Text('How will you carry parcels?', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s12),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: CourierVehicle.values
                    .map(
                      (vehicle) => ChoiceChip(
                        label: Text(vehicle.label),
                        selected: _vehicle == vehicle,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => _vehicle = vehicle),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: DesignTokens.s20),

              // Said plainly rather than buried in a privacy sheet: this asks
              // for location, and a courier should know why before the OS
              // prompt appears rather than after.
              Container(
                padding: const EdgeInsets.all(DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: DesignTokens.primaryGreen,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Text(
                        'We use your location once, now, to work out which area '
                        'to offer you parcels in. It is stored as an approximate '
                        'area, not an address.',
                        style: DesignTokens.tiny,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s24),

              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Apply to deliver',
                  disabled: busy || _vehicle == null,
                  onPressed: _apply,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Text(
                'Identity checks come next. You will not be offered parcels '
                'until those clear.',
                style: DesignTokens.tiny,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
