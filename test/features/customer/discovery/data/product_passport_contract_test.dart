import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';

/// `GET /v1/public/products/{id}/passport` is `schemaVersion: 2`. This pins
/// the three fields the app used to ignore — `subject`, `claims` and
/// `coverage` — and the defaults that decide whether a claim is shown as
/// checked or as claimed.
class _GetApiClient extends ApiClient {
  _GetApiClient(this.body) : super(dio: Dio());
  final Object? body;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => body;
}

class _AlwaysOnline implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Only isConnected is used here.');
}

Future<ProductPassport> _passport(Map<String, dynamic> body) async {
  final repo = DiscoveryRepositoryImpl(
    remoteDataSource: DiscoveryRemoteDataSource(apiClient: _GetApiClient(body)),
    networkInfo: _AlwaysOnline(),
  );
  final result = await repo.getProductPassport('p1');
  return result.getOrElse((_) => throw StateError('left'));
}

Map<String, dynamic> _claimJson({
  Object? assurance = 1,
  bool? presentAsFact,
  String statement = 'Made in Bhaktapur.',
}) => <String, dynamic>{
  'claimId': 'c1',
  'kind': 1,
  'kindLabel': 'Origin',
  'statement': statement,
  'assurance': assurance,
  'assuranceLabel': 'Recorded by the seller. Nobody has checked it.',
  'presentAsFact': ?presentAsFact,
  'issuerKind': 1,
  'issuerName': 'Himalaya Handwork',
  'recordedUtc': '2026-09-01T00:00:00Z',
  'effectiveFromUtc': '2026-09-01T00:00:00Z',
  'isInEffect': true,
};

void main() {
  group('schema 1 still maps', () {
    test(
      'a v1 payload carries no subject, no claims and no coverage',
      () async {
        final passport = await _passport(const {
          'vendorBusinessName': 'Himalaya Handwork',
          'vendorIdentityVerified': true,
          'authenticityStatement': 'Sold by a verified business.',
          'schemaVersion': 1,
          'provenance': <dynamic>[],
        });

        expect(passport.subject, isNull);
        expect(passport.claims, isEmpty);
        expect(passport.coverage, isNull);
      },
    );
  });

  group('subject', () {
    test(
      'scope, explanation and the unit flag all read off the wire',
      () async {
        final passport = await _passport(const {
          'schemaVersion': 2,
          'subject': {
            'scope': 1,
            'serialOrBatchNumber': null,
            'scopeExplanation': 'It cannot identify which physical item…',
            'identifiesPhysicalUnit': false,
          },
        });

        final subject = passport.subject!;
        expect(
          subject.scopeExplanation,
          'It cannot identify which physical item…',
        );
        expect(subject.identifiesPhysicalUnit, isFalse);
        // Null means *not known*. It is never a placeholder string.
        expect(subject.serialOrBatchNumber, isNull);
      },
    );

    test('an absent unit flag defaults to false, never to true', () async {
      final passport = await _passport(const {
        'schemaVersion': 2,
        'subject': {'scopeExplanation': 'x'},
      });

      // The safe direction: a passport is never assumed to identify the item
      // in the customer's hands.
      expect(passport.subject!.identifiesPhysicalUnit, isFalse);
    });
  });

  group('presentAsFact is the safety property', () {
    test('an absent presentAsFact defaults to false', () async {
      final passport = await _passport({
        'schemaVersion': 2,
        'claims': [_claimJson(assurance: 2)],
      });

      expect(passport.claims.single.presentAsFact, isFalse);
    });

    test('true only survives alongside a Verified assurance', () async {
      final verified = await _passport({
        'schemaVersion': 2,
        'claims': [_claimJson(assurance: 2, presentAsFact: true)],
      });
      expect(verified.claims.single.presentAsFact, isTrue);

      // A server asserting presentAsFact on a merely recorded claim is
      // contradicting itself. The app takes the cautious half.
      final recorded = await _passport({
        'schemaVersion': 2,
        'claims': [_claimJson(presentAsFact: true)],
      });
      expect(recorded.claims.single.presentAsFact, isFalse);
    });

    test('an unknown assurance can never be presented as fact', () async {
      final passport = await _passport({
        'schemaVersion': 2,
        'claims': [_claimJson(assurance: 99, presentAsFact: true)],
      });

      expect(passport.claims.single.assurance, PassportAssurance.unrecognised);
      expect(passport.claims.single.presentAsFact, isFalse);
    });
  });

  group('assurance on the wire', () {
    test('ints and names both map to the same values', () async {
      for (final (raw, expected) in <(Object, PassportAssurance)>[
        (1, PassportAssurance.recorded),
        (2, PassportAssurance.verified),
        (3, PassportAssurance.verificationFailed),
        (4, PassportAssurance.couldNotVerify),
        ('Recorded', PassportAssurance.recorded),
        ('Verified', PassportAssurance.verified),
        ('VerificationFailed', PassportAssurance.verificationFailed),
        ('CouldNotVerify', PassportAssurance.couldNotVerify),
      ]) {
        final passport = await _passport({
          'schemaVersion': 2,
          'claims': [_claimJson(assurance: raw)],
        });
        expect(passport.claims.single.assurance, expected, reason: '$raw');
      }
    });

    test('a failed claim is separated out as withdrawn', () async {
      final passport = await _passport({
        'schemaVersion': 2,
        'claims': [_claimJson(assurance: 3), _claimJson()],
      });

      expect(passport.standingClaims.length, 1);
      expect(
        passport.standingClaims.single.assurance,
        PassportAssurance.recorded,
      );
      expect(passport.withdrawnClaims.length, 1);
    });

    test(
      'a claim with no words in it is dropped, not rendered empty',
      () async {
        final passport = await _passport({
          'schemaVersion': 2,
          'claims': [_claimJson(statement: '   ')],
        });

        expect(passport.claims, isEmpty);
      },
    );
  });

  group('coverage', () {
    test('known, unknown and the summary all read off the wire', () async {
      final passport = await _passport(const {
        'schemaVersion': 2,
        'coverage': {
          'knownKinds': ['Origin'],
          'unknownKinds': ['Warranty', 'Recall or safety notice'],
          'verifiedClaimCount': 1,
          'recordedClaimCount': 0,
          'verificationFailedCount': 0,
          'couldNotVerifyCount': 0,
          'summary':
              '1 passport record: 1 independently verified by '
              'StyleMint. Anything not listed is unknown, not assumed.',
        },
      });

      final coverage = passport.coverage!;
      expect(coverage.knownKinds, ['Origin']);
      // Absent kinds are carried through by name, so the UI can say what is
      // not recorded instead of implying the listing has none of it.
      expect(coverage.unknownKinds, [
        'Warranty',
        'Recall or safety notice',
      ]);
      expect(coverage.summary, startsWith('1 passport record:'));
    });

    test('an absent coverage block is null, not an empty one', () async {
      final passport = await _passport(const {'schemaVersion': 2});
      expect(passport.coverage, isNull);
    });
  });
}
