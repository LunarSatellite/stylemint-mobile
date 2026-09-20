import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/datasources/codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/resolved_code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/repositories/codes_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';

import '../support/recording_api_client.dart';

const _link = 'https://stylemint.voyageritnepal.com/c/ABCD2345';

Map<String, dynamic> _codeJson({
  Object? code = 'ABCD2345',
  Object? kind = 'ProductTag',
  Object? status = 'Active',
  Object? url = _link,
}) => <String, dynamic>{
  'code': code,
  'kind': kind,
  'status': status,
  'url': url,
  'productId': 'p-1',
  'productName': 'Linen shirt',
  'storeId': 's-1',
  'storeName': 'Mint Thamel',
  'label': 'Front shelf',
  'scanCount': 12,
  'createdUtc': '2026-09-15T08:00:00Z',
  'revokedUtc': null,
};

class _MockRemote extends Mock implements CodesRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(CodeScanVia.link));

  group('StyleMintCodeFormat', () {
    test('accepts 8 Crockford base32 characters in any case', () {
      expect(StyleMintCodeFormat.normalize('abcd2345'), 'ABCD2345');
      expect(StyleMintCodeFormat.normalize(' 7K9M2PQR '), '7K9M2PQR');
      expect(StyleMintCodeFormat.display('ABCD2345'), 'ABCD 2345');
    });

    test('rejects other lengths, excluded letters and symbols', () {
      for (final raw in <String?>[
        null,
        '',
        'ABCD234',
        'ABCD23456',
        'ABCI2345',
        'ABCL2345',
        'ABCO2345',
        'ABCU2345',
        'ABCD-234',
      ]) {
        expect(StyleMintCodeFormat.normalize(raw), isNull, reason: '$raw');
      }
    });
  });

  group('StyleMintCodeLinks', () {
    test('keeps an https StyleMint link to the same code', () {
      expect(
        StyleMintCodeLinks.publicUrl(
          'ABCD2345',
          serverUrl: 'https://STYLEMINT.voyageritnepal.com/c/abcd2345',
        ),
        _link,
      );
    });

    test('never keeps another site, scheme, path or code', () {
      for (final serverUrl in <String?>[
        null,
        '',
        'https://evil.example/c/ABCD2345',
        'http://stylemint.voyageritnepal.com/c/ABCD2345',
        'https://stylemint.voyageritnepal.com:8443/c/ABCD2345',
        'https://stylemint.voyageritnepal.com/c/ZZZZ2345',
        'https://stylemint.voyageritnepal.com/reels/ABCD2345',
        'javascript:alert(1)',
      ]) {
        expect(
          StyleMintCodeLinks.publicUrl('ABCD2345', serverUrl: serverUrl),
          _link,
          reason: '$serverUrl',
        );
      }
    });

    test('the NFC link adds via=nfc and routes carry via', () {
      expect(StyleMintCodeLinks.nfcUrl(_link), '$_link?via=nfc');
      expect(
        StyleMintCodeLinks.route('ABCD2345', CodeScanVia.qr),
        '/c/ABCD2345?via=Qr',
      );
    });

    test('via reads in any casing and defaults to a link', () {
      expect(CodeScanVia.parse('nfc'), CodeScanVia.nfc);
      expect(CodeScanVia.parse('QR'), CodeScanVia.qr);
      expect(CodeScanVia.parse('Link'), CodeScanVia.link);
      expect(CodeScanVia.parse('bluetooth'), CodeScanVia.link);
      expect(CodeScanVia.parse(null), CodeScanVia.link);
    });
  });

  group('CodeDto', () {
    test('maps every CodeVm field', () {
      final code = CodeDto.fromJson(_codeJson()).toDomain();

      expect(code.code, 'ABCD2345');
      expect(code.kind, CodeKind.productTag);
      expect(code.status, CodeStatus.active);
      expect(code.isActive, isTrue);
      expect(code.url, _link);
      expect(code.productId, 'p-1');
      expect(code.productName, 'Linen shirt');
      expect(code.storeId, 's-1');
      expect(code.storeName, 'Mint Thamel');
      expect(code.label, 'Front shelf');
      expect(code.scanCount, 12);
      expect(code.createdUtc, DateTime.utc(2026, 9, 15, 8));
      expect(code.revokedUtc, isNull);
    });

    test('reads kinds and statuses from names or numbers', () {
      expect(parseCodeKind('ProductTag'), CodeKind.productTag);
      expect(parseCodeKind(2), CodeKind.store);
      expect(parseCodeKind('profile'), CodeKind.profile);
      expect(parseCodeKind(4), CodeKind.unknown);
      expect(parseCodeKind('VendorPayment'), CodeKind.unknown);
      expect(parseCodeStatus('Revoked'), CodeStatus.revoked);
      expect(parseCodeStatus(1), CodeStatus.active);
      expect(parseCodeStatus(null), CodeStatus.unknown);
    });

    test('a link to anywhere else is replaced by the StyleMint link', () {
      final code = CodeDto.fromJson(
        _codeJson(code: 'abcd2345', url: 'https://tiktok.com/@shop'),
      ).toDomain();

      expect(code.code, 'ABCD2345');
      expect(code.url, _link);
    });

    test('pages drop entries without a valid code', () {
      final codes = CodeDto.listFromPage(<String, dynamic>{
        'items': [
          _codeJson(),
          _codeJson(code: 'NOPE'),
          'not-a-code',
        ],
        'nextCursor': null,
      });

      expect(codes.single.code, 'ABCD2345');
      expect(CodeDto.listFromPage(null), isEmpty);
    });

    test('a malformed code throws instead of becoming a bad link', () {
      expect(
        () => CodeDto.fromJson(_codeJson(code: 'BAD')).toDomain(),
        throwsFormatException,
      );
    });
  });

  group('ResolvedCodeDto', () {
    test('maps a product tag', () {
      final resolved = ResolvedCodeDto.fromJson(<String, dynamic>{
        'code': 'ABCD2345',
        'kind': 'ProductTag',
        'productId': 'p-1',
        'storeId': 's-1',
        'storeName': 'Mint Thamel',
        'storeCity': 'Kathmandu',
        'vendorAccountId': 'v-1',
        'vendorDisplayName': 'Mint Studio',
      }).toDomain(requestedCode: 'ABCD2345');

      expect(resolved.kind, CodeKind.productTag);
      expect(resolved.productId, 'p-1');
      expect(resolved.storeId, 's-1');
      expect(resolved.storeName, 'Mint Thamel');
      expect(resolved.storeCity, 'Kathmandu');
      expect(resolved.vendorAccountId, 'v-1');
      expect(resolved.vendorDisplayName, 'Mint Studio');
      expect(resolved.accountId, isNull);
    });

    test('maps a profile and strips the @ from the handle', () {
      final resolved = ResolvedCodeDto.fromJson(<String, dynamic>{
        'code': '7K9M2PQR',
        'kind': 3,
        'accountId': 'a-1',
        'displayName': 'Asha Rai',
        'handle': '@asha',
        'avatarUrl': 'https://cdn.stylemint.app/a.jpg',
      }).toDomain(requestedCode: '7K9M2PQR');

      expect(resolved.kind, CodeKind.profile);
      expect(resolved.accountId, 'a-1');
      expect(resolved.displayName, 'Asha Rai');
      expect(resolved.handle, 'asha');
      expect(resolved.avatarUrl, 'https://cdn.stylemint.app/a.jpg');
    });

    test('falls back to the requested code', () {
      final resolved = ResolvedCodeDto.fromJson(<String, dynamic>{
        'kind': 'Store',
        'storeId': 's-1',
      }).toDomain(requestedCode: 'ABCD2345');

      expect(resolved.code, 'ABCD2345');
      expect(resolved.kind, CodeKind.store);
    });
  });

  group('CodesRemoteDataSource', () {
    test('resolve POSTs via with an Idempotency-Key and the token', () async {
      final api = RecordingApiClient(
        (_) => <String, dynamic>{
          'code': 'ABCD2345',
          'kind': 'Store',
          'storeId': 's-1',
        },
      );

      final dto = await CodesRemoteDataSource(apiClient: api).resolve(
        code: 'ABCD2345',
        via: CodeScanVia.nfc,
        idempotencyKey: 'key-1',
      );

      expect(api.last.method, 'POST');
      expect(api.last.uri, '/v1/public/codes/ABCD2345/resolve');
      expect(api.last.data, <String, dynamic>{'via': 'Nfc'});
      expect(api.last.header('Idempotency-Key'), 'key-1');
      expect(api.last.header('requiresToken'), isTrue);
      expect(dto.kind, CodeKind.store);
    });

    test(
      'the profile code is get-or-created and rotated under /v1/me',
      () async {
        final api = RecordingApiClient(
          (_) => _codeJson(kind: 'Profile', code: '7K9M2PQR'),
        );
        final source = CodesRemoteDataSource(apiClient: api);

        final current = await source.getMyProfileCode(idempotencyKey: 'k-1');
        final rotated = await source.rotateMyProfileCode(idempotencyKey: 'k-2');

        expect(api.calls.map((c) => '${c.method} ${c.uri}'), [
          'POST /v1/me/profile-code',
          'POST /v1/me/profile-code/rotate',
        ]);
        expect(api.calls.map((c) => c.header('Idempotency-Key')), [
          'k-1',
          'k-2',
        ]);
        expect(current.kind, CodeKind.profile);
        expect(rotated.code, '7K9M2PQR');
      },
    );

    test('a body that is not an object is a format error', () async {
      final api = RecordingApiClient((_) => <dynamic>[]);

      expect(
        () => CodesRemoteDataSource(apiClient: api).getMyProfileCode(
          idempotencyKey: 'k',
        ),
        throwsFormatException,
      );
    });
  });

  group('CodesRepositoryImpl', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    CodesRepositoryImpl repo({bool connected = true}) => CodesRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: FakeNetworkInfo(connected: connected),
    );

    void stubResolve(Object Function() answer) {
      when(
        () => remote.resolve(
          code: any(named: 'code'),
          via: any(named: 'via'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {
        final result = answer();
        if (result is Exception) throw result;
        return result as ResolvedCodeDto;
      });
    }

    test('resolves to the domain with a fresh key each time', () async {
      stubResolve(
        () => const ResolvedCodeDto(
          code: 'ABCD2345',
          kind: CodeKind.productTag,
          productId: 'p-1',
        ),
      );
      final repository = repo();

      final first = await repository.resolve('ABCD2345', CodeScanVia.qr);
      await repository.resolve('ABCD2345', CodeScanVia.qr);

      expect(first.getRight().toNullable()!.productId, 'p-1');
      final keys = verify(
        () => remote.resolve(
          code: 'ABCD2345',
          via: CodeScanVia.qr,
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(2));
    });

    test('an unknown or revoked code is notFound', () async {
      stubResolve(
        () => dioError(
          404,
          body: <String, dynamic>{
            'title': "Code 'ABCD2345' was not found.",
            'errorCode': 'entity.not_found',
          },
        ),
      );

      final result = await repo().resolve('ABCD2345', CodeScanVia.link);

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('a 429 keeps the backend code for a retryable message', () async {
      stubResolve(
        () => dioError(
          429,
          body: <String, dynamic>{
            'title': 'Too many scans. Try again in a minute.',
            'errorCode': 'system.rate_limited',
          },
        ),
      );

      final failure = (await repo().resolve(
        'ABCD2345',
        CodeScanVia.qr,
      )).getLeft().toNullable()!;

      expect(failure.validationCode, 'system.rate_limited');
      expect(
        NetworkExceptions.getMessage(failure),
        'Too many scans. Try again in a minute.',
      );
    });

    test('a 5xx is serverUnavailable', () async {
      when(
        () => remote.getMyProfileCode(
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(dioError(503));

      final result = await repo().getMyProfileCode();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.serverUnavailable(),
      );
    });

    test('offline is noInternetConnection without calling the API', () async {
      final result = await repo(connected: false).rotateMyProfileCode();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(
        () => remote.rotateMyProfileCode(
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    test('a malformed code in the answer is unexpectedError', () async {
      when(
        () => remote.getMyProfileCode(
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => CodeDto.fromJson(_codeJson(code: 'oops')),
      );

      final result = await repo().getMyProfileCode();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });
  });
}
