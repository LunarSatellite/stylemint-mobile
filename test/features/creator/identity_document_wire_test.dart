import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';

/// These numbers go on the wire and are enforced by Postgres check
/// constraints, not by validation — so a wrong one surfaces as a 500 from a
/// `DELETE`-shaped error deep in a service, never as "that field is invalid".
///
/// `IdentityDocumentSide` was off by one (`notApplicable(0), front(1),
/// back(2)` against a backend of `1, 2, 3`). Every document registration was
/// rejected:
///   * side 0 fails `ck_verification_documents_side_range` (1..3);
///   * side 1 reads as NotApplicable, and a two-sided type must be Front or
///     Back — `ck_verification_documents_side_matches_type`;
///   * side 2 reads as Front, failing the same rule for the back page.
///
/// Nothing could be uploaded at all, by couriers or creators.
void main() {
  group('IdentityDocumentType wire values', () {
    test('match StyleMint.Modules.Identity.Enums.VerificationDocumentType', () {
      expect(IdentityDocumentType.passport.wireValue, 1);
      expect(IdentityDocumentType.nationalIdCard.wireValue, 2);
      expect(IdentityDocumentType.driversLicense.wireValue, 3);
      expect(IdentityDocumentType.residencePermit.wireValue, 4);
      expect(IdentityDocumentType.selfiePhoto.wireValue, 5);
      expect(IdentityDocumentType.addressProof.wireValue, 6);
    });

    test('needsBothSides covers exactly the two-sided types', () {
      // The server's side_matches_type constraint names 2, 3 and 4.
      final twoSided = IdentityDocumentType.values
          .where((t) => t.needsBothSides)
          .map((t) => t.wireValue)
          .toSet();
      expect(twoSided, {2, 3, 4});
    });
  });

  group('IdentityDocumentSide wire values', () {
    test('match StyleMint.Modules.Identity.Enums.VerificationDocumentSide', () {
      expect(IdentityDocumentSide.notApplicable.wireValue, 1);
      expect(IdentityDocumentSide.front.wireValue, 2);
      expect(IdentityDocumentSide.back.wireValue, 3);
    });

    test('none is 0 — the range constraint starts at 1', () {
      for (final side in IdentityDocumentSide.values) {
        expect(
          side.wireValue,
          inInclusiveRange(1, 3),
          reason: '${side.name} must satisfy side BETWEEN 1 AND 3',
        );
      }
    });
  });
}
