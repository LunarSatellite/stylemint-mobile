import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/memory_vault_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';

/// Records what the vault actually asked the network for. The point of
/// these tests is that each purpose reaches its *own* endpoint with its
/// *own* wire code — the previous client collapsed all four into one
/// `memoryPaused` boolean and nobody noticed for a release.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.consents = const []}) : super(dio: Dio());

  final List<Map<String, dynamic>> consents;

  final List<String> gets = [];
  final List<({String uri, dynamic data})> posts = [];
  final List<String> deletes = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    gets.add(uri);
    if (uri.endsWith('/memories/consents')) return consents;
    if (uri.endsWith('/memories')) return <dynamic>[];
    return <String, dynamic>{'memoryPaused': false};
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add((uri: uri, data: data));
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deletes.add(uri);
    return null;
  }
}

Map<String, dynamic> _decision(
  int purpose, {
  bool permitted = false,
  int basis = 0,
  String reason = 'consent.undecided',
  bool needsDecision = true,
  String? expiresUtc,
}) => {
  'purpose': purpose,
  'permitted': permitted,
  'basis': basis,
  'reason': reason,
  'needsDecision': needsDecision,
  'expiresUtc': expiresUtc,
};

void main() {
  group('reading a decision', () {
    test('maps integer enums, which is how the API serialises them', () {
      final consent = memoryConsentFromJson(
        _decision(
          3,
          permitted: true,
          basis: 1,
          reason: 'consent.granted',
          needsDecision: false,
          expiresUtc: '2026-12-01T00:00:00Z',
        ),
      );

      expect(consent.purpose, MemoryPurpose.recommendations);
      expect(consent.purposeCode, 3);
      expect(consent.permitted, isTrue);
      expect(consent.basis, ConsentBasis.purposeGrant);
      expect(consent.needsDecision, isFalse);
      expect(consent.expiresUtc?.toUtc(), DateTime.utc(2026, 12));
      expect(consent.standing, ConsentStanding.granted);
    });

    test('also reads enum names, in case the API starts sending them', () {
      final consent = memoryConsentFromJson({
        'purpose': 'ProactiveOutreach',
        'permitted': false,
        'basis': 'None',
        'reason': 'consent.undecided',
        'needsDecision': true,
      });

      expect(consent.purpose, MemoryPurpose.proactiveOutreach);
      expect(consent.basis, ConsentBasis.none);
    });

    test('a malformed row is off, never on', () {
      final consent = memoryConsentFromJson(<String, dynamic>{});

      expect(consent.permitted, isFalse);
      expect(consent.standing, ConsentStanding.undecided);
    });

    test('a purpose from a newer backend survives and stays refusable', () {
      final consent = memoryConsentFromJson(
        _decision(99),
      );

      expect(consent.purpose, isNull, reason: 'this build cannot name it');
      expect(consent.purposeCode, 99, reason: 'but it can still revoke it');
      expect(consent.permitted, isFalse);
    });
  });

  group('standings', () {
    ConsentStanding standingOf(Map<String, dynamic> json) =>
        memoryConsentFromJson(json).standing;

    test('undecided, refused and lapsed are three different things', () {
      expect(
        standingOf(_decision(3)),
        ConsentStanding.undecided,
      );
      expect(
        standingOf(_decision(3, reason: 'consent.revoked')),
        ConsentStanding.refused,
      );
      expect(
        standingOf(_decision(3, reason: 'consent.expired')),
        ConsentStanding.expired,
      );
    });

    test('the legacy basis is permitted but still wants an answer', () {
      final consent = memoryConsentFromJson(
        _decision(
          1,
          permitted: true,
          basis: 2,
          reason: 'consent.legacy_pause_basis',
        ),
      );

      expect(consent.standing, ConsentStanding.legacyBasis);
      expect(consent.needsDecision, isTrue);
    });

    test('an unreadable state reads as unreadable, never as permission', () {
      final consent = memoryConsentFromJson(
        _decision(2, reason: 'consent.unreadable', needsDecision: false),
      );

      expect(consent.standing, ConsentStanding.unreadable);
      expect(consent.permitted, isFalse);
    });

    test('the global pause overrides whatever the purpose says', () {
      final granted = memoryConsentFromJson(
        _decision(
          1,
          permitted: true,
          basis: 1,
          reason: 'consent.granted',
          needsDecision: false,
        ),
      );

      expect(granted.standing, ConsentStanding.granted);
      expect(
        granted.standingWhilePaused(paused: true),
        ConsentStanding.pausedGlobally,
      );
      expect(
        granted.standingWhilePaused(paused: false),
        ConsentStanding.granted,
      );
    });

    test('a reason this build does not know asks rather than assumes', () {
      expect(
        standingOf(_decision(4, reason: 'consent.some_future_code')),
        ConsentStanding.undecided,
      );
    });
  });

  group('a purpose the backend never mentioned', () {
    test('reads as undecided, not as agreement', () {
      const vault = MemoryVault(paused: false, memories: []);

      for (final purpose in MemoryPurpose.values) {
        final consent = vault.consentFor(purpose);
        expect(consent.standing, ConsentStanding.undecided);
        expect(consent.permitted, isFalse);
      }
    });
  });

  group('endpoints', () {
    test('each purpose grants through its own wire code', () async {
      final api = _RecordingApiClient();
      final source = MemoryVaultRemoteDataSource(apiClient: api);

      for (final purpose in MemoryPurpose.values) {
        await source.grantConsent(
          purpose: purpose,
          explanation: MemoryPurposeCopy.explanationOf(purpose),
        );
      }

      expect(api.posts, hasLength(4));
      expect(
        api.posts.map((p) => p.uri).toSet(),
        {'/v1/customer/companion/memories/consents'},
      );
      expect(
        api.posts
            .map((p) => (p.data as Map<String, dynamic>)['purpose'])
            .toList(),
        [1, 2, 3, 4],
      );
    });

    test('the explanation sent is byte-identical to the one shown', () async {
      final api = _RecordingApiClient();
      final source = MemoryVaultRemoteDataSource(apiClient: api);

      for (final purpose in MemoryPurpose.values) {
        await source.grantConsent(
          purpose: purpose,
          explanation: MemoryPurposeCopy.explanationOf(purpose),
        );
      }

      for (var i = 0; i < MemoryPurpose.values.length; i++) {
        final shown = MemoryPurposeCopy.explanationOf(
          MemoryPurpose.values[i],
        );
        final sent =
            (api.posts[i].data as Map<String, dynamic>)['explanation']
                as String;
        expect(sent, shown);
        expect(sent.codeUnits, shown.codeUnits);
      }
    });

    test('each purpose revokes through its own URL', () async {
      final api = _RecordingApiClient();
      final source = MemoryVaultRemoteDataSource(apiClient: api);

      for (final purpose in MemoryPurpose.values) {
        await source.revokeConsent(purpose.wireValue);
      }
      await source.revokeConsent(99);

      expect(api.deletes, [
        '/v1/customer/companion/memories/consents/1',
        '/v1/customer/companion/memories/consents/2',
        '/v1/customer/companion/memories/consents/3',
        '/v1/customer/companion/memories/consents/4',
        '/v1/customer/companion/memories/consents/99',
      ]);
    });

    test('loading the vault also loads the decisions', () async {
      final api = _RecordingApiClient(
        consents: [
          _decision(
            1,
            permitted: true,
            basis: 2,
            reason: 'consent.legacy_pause_basis',
          ),
          _decision(3),
        ],
      );
      final vault = await MemoryVaultRemoteDataSource(apiClient: api).load();

      expect(vault.consents, hasLength(2));
      expect(
        vault.consentFor(MemoryPurpose.companionRecall).standing,
        ConsentStanding.legacyBasis,
      );
      expect(
        vault.consentFor(MemoryPurpose.proactiveOutreach).standing,
        ConsentStanding.undecided,
        reason: 'not reported is not decided',
      );
    });
  });

  group('the words', () {
    test('every purpose explains itself and the cost of refusing', () {
      for (final purpose in MemoryPurpose.values) {
        final explanation = MemoryPurposeCopy.explanationOf(purpose);
        expect(explanation, isNotEmpty);
        expect(
          explanation.length,
          lessThanOrEqualTo(500),
          reason: 'the backend caps the stored explanation at 500',
        );
        expect(
          explanation,
          contains('Refuse and'),
          reason: 'hiding the cost of refusing is its own dark pattern',
        );
        expect(MemoryPurposeCopy.titleOf(purpose), isNotEmpty);
        expect(MemoryPurposeCopy.spokenNameOf(purpose), isNotEmpty);
      }
    });

    test('no two purposes share their words', () {
      final explanations = {
        for (final purpose in MemoryPurpose.values)
          MemoryPurposeCopy.explanationOf(purpose),
      };
      expect(explanations, hasLength(MemoryPurpose.values.length));
    });
  });
}
