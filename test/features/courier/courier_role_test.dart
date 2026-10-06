import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/identity_roles.dart';

/// Delivery is a real Identity role now, so two things have to stay in step
/// with the server or the app shows a courier a role the backend refuses to
/// activate — silently, because activation is fire-and-forget.
void main() {
  group('IdentityRoles', () {
    test('mirrors the backend RoleType values', () {
      expect(IdentityRoles.customer, 1);
      expect(IdentityRoles.creator, 2);
      expect(IdentityRoles.vendor, 3);
      expect(IdentityRoles.courier, 4);
    });

    test('the role picker option is the Courier role, not a sentinel', () {
      // It used to be a sentinel deliberately kept out of the role API. If
      // these ever diverge again, the picker posts a role id the backend's
      // enum does not define.
      expect(deliveryPartnerOption, IdentityRoles.courier);
    });
  });

  group('CourierProfileState.hasClearedChecks', () {
    test('is exactly Onboarded and Active', () {
      // Must equal DeliveryCourierStandingLookup's rule on the server.
      final cleared = CourierProfileState.values
          .where((s) => s.hasClearedChecks)
          .toSet();
      expect(cleared, {
        CourierProfileState.onboarded,
        CourierProfileState.active,
      });
    });

    test('excludes the states that have not been vetted', () {
      expect(CourierProfileState.applied.hasClearedChecks, isFalse);
      expect(CourierProfileState.kycInReview.hasClearedChecks, isFalse);
      expect(CourierProfileState.rejected.hasClearedChecks, isFalse);
    });

    test('excludes the states that had it taken away', () {
      // A suspended courier holding an active delivery role would have the
      // role disagree with the only thing that gates carrying a parcel.
      expect(CourierProfileState.suspended.hasClearedChecks, isFalse);
      expect(CourierProfileState.banned.hasClearedChecks, isFalse);
    });

    // 1e44f097 made canCarry include Onboarded, so the two now agree on
    // membership: the server's candidate query filters
    // IsOnline && State IN (Onboarded, Active), and the app has to match or it
    // offers a capability the router refuses. They are still separate getters
    // because they answer different questions — "has been vetted" and "may be
    // handed a parcel" — and only one of them is tied to that query.
    test('agrees with canCarry: Onboarded has cleared review and may carry', () {
      expect(CourierProfileState.onboarded.hasClearedChecks, isTrue);
      expect(CourierProfileState.onboarded.canCarry, isTrue);
      expect(CourierProfileState.active.hasClearedChecks, isTrue);
      expect(CourierProfileState.active.canCarry, isTrue);
    });
  });
}
