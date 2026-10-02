import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';

/// The role picker stores what a guest tapped and every post-login screen has
/// to resume it. Each of those screens used to inline
/// `pendingRole == 2 || pendingRole == 3`, so the delivery-partner option
/// would have been dropped by whichever one was missed -- the user would tap
/// "I am a delivery partner", sign in, and land on the shopping feed with no
/// indication the choice had been thrown away.
void main() {
  group('pendingRoleNeedsResume', () {
    test('resumes the options that need an authenticated account', () {
      expect(pendingRoleNeedsResume(2), isTrue, reason: 'Creator');
      expect(pendingRoleNeedsResume(3), isTrue, reason: 'Vendor');
      expect(
        pendingRoleNeedsResume(deliveryPartnerOption),
        isTrue,
        reason: 'Delivery partner',
      );
    });

    test('does not resume Customer, which needs no application', () {
      expect(pendingRoleNeedsResume(1), isFalse);
    });

    test('does not resume when nothing was picked', () {
      expect(pendingRoleNeedsResume(null), isFalse);
    });

    test('delivery partner is not a backend RoleType value', () {
      // RoleType stops at Vendor = 3. If someone ever adds a fourth real role
      // to Identity, this sentinel collides with it and the picker would post
      // a role request for a courier -- so it must stay outside that range.
      expect(deliveryPartnerOption, greaterThan(3));
    });
  });
}
