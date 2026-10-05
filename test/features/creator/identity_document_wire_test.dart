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

  /// These two arrive as NUMBERS. The API adds no global
  /// `JsonStringEnumConverter`, and neither `KycSessionStatus` nor
  /// `VerificationDocumentStatus` carries its own `[JsonConverter]`, so the
  /// payload holds `"status": 1`. Reading that with `as String?` threw
  /// `_TypeError` in the first call of the upload flow and stopped the whole
  /// courier KYC submission before a single document was sent.
  group('status wire values', () {
    test('IdentityDocumentStatus matches VerificationDocumentStatus', () {
      expect(IdentityDocumentStatus.uploaded.wireValue, 1);
      expect(IdentityDocumentStatus.underReview.wireValue, 2);
      expect(IdentityDocumentStatus.approved.wireValue, 3);
      expect(IdentityDocumentStatus.rejected.wireValue, 4);
      expect(IdentityDocumentStatus.expired.wireValue, 5);
    });

    test('KycSessionStatus matches the server enum', () {
      expect(KycSessionStatus.pending.wireValue, 1);
      expect(KycSessionStatus.submitted.wireValue, 2);
      expect(KycSessionStatus.underReview.wireValue, 3);
      expect(KycSessionStatus.approved.wireValue, 4);
      expect(KycSessionStatus.rejected.wireValue, 5);
      expect(KycSessionStatus.expired.wireValue, 6);
    });
  });

  group('wireEnum', () {
    test('reads the integer the server actually sends', () {
      expect(
        wireEnum(1, KycSessionStatus.values),
        KycSessionStatus.pending,
      );
      expect(
        wireEnum(4, IdentityDocumentStatus.values),
        IdentityDocumentStatus.rejected,
      );
    });

    test('also reads a name, so adding a string converter cannot break us', () {
      // Server member names, including the casing and spelling they use.
      expect(
        wireEnum('UnderReview', KycSessionStatus.values),
        KycSessionStatus.underReview,
      );
      expect(
        wireEnum('under_review', IdentityDocumentStatus.values),
        IdentityDocumentStatus.underReview,
      );
      expect(
        wireEnum('Uploaded', IdentityDocumentStatus.values),
        IdentityDocumentStatus.uploaded,
      );
    });

    test('returns null rather than throwing on anything unexpected', () {
      // The whole point: the caller substitutes a default, and a payload we
      // do not recognise cannot take down the flow that reads it.
      expect(wireEnum(null, KycSessionStatus.values), isNull);
      expect(wireEnum(99, KycSessionStatus.values), isNull);
      expect(wireEnum('', KycSessionStatus.values), isNull);
      expect(wireEnum('nonsense', KycSessionStatus.values), isNull);
      expect(wireEnum(<String, Object>{}, KycSessionStatus.values), isNull);
    });
  });
}
