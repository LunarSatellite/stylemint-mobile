import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/datasources/sponsored_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/models/sponsored_listing_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/data/repositories/sponsored_products_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';

const _productId = '11111111-1111-1111-1111-111111111111';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? method;
  String? uri;
  Object? data;
  Options? options;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    method = 'GET';
    this.uri = uri;
    this.options = options;
    return body;
  }

  @override
  Future<dynamic> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    method = 'PUT';
    this.uri = uri;
    this.data = data;
    this.options = options;
    return body;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    method = 'POST';
    this.uri = uri;
    this.data = data;
    this.options = options;
    return body;
  }
}

class _MockRemote extends Mock implements SponsoredProductsRemoteDataSource {}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

Map<String, dynamic> _listingJson({
  Object? state = 1,
  Object? isLive = true,
  Object? endsUtc,
}) => <String, dynamic>{
  'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'productId': _productId,
  'productName': 'Linen shirt',
  'state': state,
  'isLive': isLive,
  'dailyImpressionCap': 500,
  'endsUtc': endsUtc,
  'impressionsToday': 12,
  'impressionsLast7Days': 340,
  'unitsSoldLast7Days': 9,
  'unitsSoldPrevious7Days': 4,
  'disclosure':
      'Shoppers see it labelled "Sponsored", only when it matches their '
      'search and is in stock, at most 500 times a day.',
  'salesComparisonNote':
      'Units sold in the last 7 days against the 7 days before. Other things '
      'change too, so treat the difference as a guide, not proof.',
  'createdUtc': '2026-09-01T08:00:00+00:00',
  'updatedUtc': '2026-09-10T08:00:00+00:00',
};

DioException _dioError(int? status, {Object? body, DioExceptionType? type}) {
  final options = RequestOptions(
    path: '/v1/vendor/store/sponsored/$_productId',
  );
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(DateTime.utc(2000)));

  group('SponsoredListingDto', () {
    test('maps every field of the backend DTO', () {
      final listing = SponsoredListingDto.fromJson(
        _listingJson(endsUtc: '2026-09-20T18:15:00+00:00'),
      ).toDomain();

      expect(listing.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(listing.productId, _productId);
      expect(listing.productName, 'Linen shirt');
      expect(listing.state, SponsoredListingState.active);
      expect(listing.isLive, isTrue);
      expect(listing.status, SponsorshipStatus.live);
      expect(listing.dailyImpressionCap, 500);
      expect(listing.endsUtc, DateTime.utc(2026, 9, 20, 18, 15));
      expect(listing.impressionsToday, 12);
      expect(listing.impressionsLast7Days, 340);
      expect(listing.unitsSoldLast7Days, 9);
      expect(listing.unitsSoldPrevious7Days, 4);
      expect(listing.disclosure, startsWith('Shoppers see it labelled'));
      expect(listing.salesComparisonNote, endsWith('a guide, not proof.'));
      expect(listing.createdUtc, DateTime.utc(2026, 9, 1, 8));
      expect(listing.updatedUtc, DateTime.utc(2026, 9, 10, 8));
    });

    test('reads state from ints, numeric strings and names alike', () {
      for (final raw in <Object>[1, 1.0, '1', 'Active', 'ACTIVE', 'active']) {
        expect(
          parseSponsoredListingState(raw),
          SponsoredListingState.active,
          reason: '$raw',
        );
      }
      for (final raw in <Object>[2, '2', 'Paused', 'paused']) {
        expect(
          parseSponsoredListingState(raw),
          SponsoredListingState.paused,
          reason: '$raw',
        );
      }
      for (final raw in <Object?>[0, 7, 'Boosted', null, true]) {
        expect(
          parseSponsoredListingState(raw),
          SponsoredListingState.unknown,
          reason: '$raw',
        );
      }
    });

    test('Live, Paused and Ended come from state and isLive', () {
      SponsorshipStatus statusOf(Object state, {required bool isLive}) =>
          SponsoredListingDto.fromJson(
            _listingJson(state: state, isLive: isLive),
          ).toDomain().status;

      expect(statusOf(1, isLive: true), SponsorshipStatus.live);
      expect(statusOf('Paused', isLive: false), SponsorshipStatus.paused);
      // Switched on, but its end date has passed.
      expect(statusOf('Active', isLive: false), SponsorshipStatus.ended);
    });

    test('a partial payload degrades to safe defaults', () {
      final listing = SponsoredListingDto.fromJson(<String, dynamic>{
        'productId': _productId,
        'state': 1,
        'impressionsToday': '7',
        'impressionsLast7Days': null,
        'endsUtc': '',
      }).toDomain();

      expect(listing.productName, '');
      expect(listing.isLive, isFalse);
      expect(listing.impressionsToday, 7);
      expect(listing.impressionsLast7Days, 0);
      expect(listing.unitsSoldLast7Days, 0);
      expect(listing.endsUtc, isNull);
      expect(listing.disclosure, '');
    });

    test('the list drops entries without a product id and non-lists', () {
      expect(SponsoredListingDto.listFromJson(null), isEmpty);
      expect(SponsoredListingDto.listFromJson(<String, dynamic>{}), isEmpty);

      final list = SponsoredListingDto.listFromJson([
        _listingJson(),
        <String, dynamic>{'productName': 'No id', 'state': 1},
        'not-a-listing',
      ]);
      expect(list.single.productId, _productId);
    });
  });

  group('SponsoredProductsRemoteDataSource', () {
    test('GET lists the vendor sponsorships', () async {
      final api = _RecordingApiClient([_listingJson()]);

      final list = await SponsoredProductsRemoteDataSource(
        apiClient: api,
      ).getSponsoredListings();

      expect(api.method, 'GET');
      expect(api.uri, '/v1/vendor/store/sponsored');
      expect(list.single.productName, 'Linen shirt');
    });

    test('PUT sends the cap, the UTC end and an Idempotency-Key', () async {
      final api = _RecordingApiClient(_listingJson());

      final dto = await SponsoredProductsRemoteDataSource(apiClient: api)
          .sponsor(
            productId: _productId,
            dailyImpressionCap: 250,
            endsUtc: DateTime.utc(2026, 9, 20, 18, 15),
            idempotencyKey: 'key-1',
          );

      expect(api.method, 'PUT');
      expect(api.uri, '/v1/vendor/store/sponsored/$_productId');
      expect(api.data, <String, dynamic>{
        'dailyImpressionCap': 250,
        'endsUtc': '2026-09-20T18:15:00.000Z',
      });
      expect(api.options?.headers?['Idempotency-Key'], 'key-1');
      expect(api.options?.headers?['requiresToken'], isTrue);
      expect(dto.productId, _productId);
    });

    test('PUT sends endsUtc null when it runs until paused', () async {
      final api = _RecordingApiClient(_listingJson());

      await SponsoredProductsRemoteDataSource(apiClient: api).sponsor(
        productId: _productId,
        dailyImpressionCap: 10,
        idempotencyKey: 'key-2',
      );

      final body = api.data! as Map<String, dynamic>;
      expect(body.containsKey('endsUtc'), isTrue);
      expect(body['endsUtc'], isNull);
    });

    test('POST pauses with an Idempotency-Key', () async {
      final api = _RecordingApiClient(_listingJson(state: 2, isLive: false));

      final dto = await SponsoredProductsRemoteDataSource(
        apiClient: api,
      ).pause(productId: _productId, idempotencyKey: 'key-3');

      expect(api.method, 'POST');
      expect(api.uri, '/v1/vendor/store/sponsored/$_productId/pause');
      expect(api.options?.headers?['Idempotency-Key'], 'key-3');
      expect(api.options?.headers?['requiresToken'], isTrue);
      expect(dto.state, SponsoredListingState.paused);
    });
  });

  group('SponsoredProductsRepositoryImpl', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    SponsoredProductsRepositoryImpl repo({bool connected = true}) =>
        SponsoredProductsRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: _Network(connected: connected),
        );

    void stubSponsor(Object Function() answer) {
      when(
        () => remote.sponsor(
          productId: any(named: 'productId'),
          dailyImpressionCap: any(named: 'dailyImpressionCap'),
          endsUtc: any(named: 'endsUtc'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {
        final result = answer();
        if (result is DioException) throw result;
        return result as SponsoredListingDto;
      });
    }

    Future<NetworkExceptions> sponsorFailure(DioException error) async {
      stubSponsor(() => error);
      final result = await repo().sponsor(
        productId: _productId,
        dailyImpressionCap: 5,
      );
      return result.getLeft().toNullable()!;
    }

    test('maps the list to domain listings', () async {
      when(() => remote.getSponsoredListings()).thenAnswer(
        (_) async => [SponsoredListingDto.fromJson(_listingJson())],
      );

      final result = await repo().getSponsoredListings();

      expect(
        result.getRight().toNullable()!.single.status,
        SponsorshipStatus.live,
      );
    });

    test('sends a fresh Idempotency-Key on every save and pause', () async {
      stubSponsor(() => SponsoredListingDto.fromJson(_listingJson()));
      when(
        () => remote.pause(
          productId: any(named: 'productId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => SponsoredListingDto.fromJson(_listingJson()));

      final repository = repo();
      await repository.sponsor(productId: _productId, dailyImpressionCap: 50);
      await repository.sponsor(productId: _productId, dailyImpressionCap: 50);
      await repository.pause(_productId);
      await repository.pause(_productId);

      final saveKeys = verify(
        () => remote.sponsor(
          productId: _productId,
          dailyImpressionCap: 50,
          endsUtc: any(named: 'endsUtc'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      final pauseKeys = verify(
        () => remote.pause(
          productId: _productId,
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      final keys = [...saveKeys, ...pauseKeys].cast<String>();
      expect(keys, hasLength(4));
      expect(keys.toSet(), hasLength(4));
      expect(keys.every((k) => k.length == 36), isTrue);
    });

    test(
      'a 400 from request validation routes errors[] to form fields',
      () async {
        final failure = await sponsorFailure(
          _dioError(
            400,
            body: <String, dynamic>{
              'title': 'One or more validation errors occurred.',
              'errorCode': 'validation.multiple_errors',
              'errors': [
                <String, dynamic>{
                  'field': 'DailyImpressionCap',
                  'code': 'validation.invalid',
                  'message':
                      'Choose between 10 and 10,000 sponsored views a day.',
                },
                <String, dynamic>{
                  'field': 'EndsUtc',
                  'code': 'validation.invalid',
                  'message': 'The end date must be in the future.',
                },
              ],
            },
          ),
        );

        final form = SponsorFormErrors.from(failure);
        expect(
          form.dailyImpressionCap,
          'Choose between 10 and 10,000 sponsored views a day.',
        );
        expect(form.endsUtc, 'The end date must be in the future.');
        expect(form.general, isNull);
        expect(
          sponsoredProductsErrorMessage(failure),
          'Choose between 10 and 10,000 sponsored views a day.\n'
          'The end date must be in the future.',
        );
        expect(isSponsorshipConflict(failure), isFalse);
      },
    );

    test(
      'a 400 rule violation keeps the backend sentence as a general error',
      () async {
        final failure = await sponsorFailure(
          _dioError(
            400,
            body: <String, dynamic>{
              'title': 'Only live products can be sponsored.',
              'errorCode': 'rule.violation',
            },
          ),
        );

        expect(failure.validationCode, 'rule.violation');
        final form = SponsorFormErrors.from(failure);
        expect(form.general, 'Only live products can be sponsored.');
        expect(form.dailyImpressionCap, isNull);
        expect(form.endsUtc, isNull);
      },
    );

    test(
      'a 400 out-of-range with a camelCase field goes under that field',
      () async {
        final capFailure = await sponsorFailure(
          _dioError(
            400,
            body: <String, dynamic>{
              'title': 'Choose between 10 and 10000 sponsored views a day.',
              'errorCode': 'validation.out_of_range',
              'field': 'dailyImpressionCap',
            },
          ),
        );
        final endsFailure = await sponsorFailure(
          _dioError(
            400,
            body: <String, dynamic>{
              'title': 'The end date must be in the future.',
              'errorCode': 'validation.out_of_range',
              'field': 'endsUtc',
            },
          ),
        );

        final cap = SponsorFormErrors.from(capFailure);
        expect(
          cap.dailyImpressionCap,
          'Choose between 10 and 10000 sponsored views a day.',
        );
        expect(cap.general, isNull);
        final ends = SponsorFormErrors.from(endsFailure);
        expect(ends.endsUtc, 'The end date must be in the future.');
        expect(ends.general, isNull);
      },
    );

    test('a 404 shows our own copy, never the id-bearing title', () async {
      final failure = await sponsorFailure(
        _dioError(
          404,
          body: <String, dynamic>{
            'title': "Product '$_productId' was not found.",
            'errorCode': 'entity.not_found',
          },
        ),
      );

      expect(failure, const NetworkExceptions.notFound());
      expect(failure.isNotFound, isTrue);
      expect(
        sponsoredProductsErrorMessage(failure),
        "We couldn't find that product in your store.",
      );
      expect(
        SponsorFormErrors.from(failure).general,
        sponsoredProductNotFoundMessage,
      );
    });

    test('a 409 is a sponsorship conflict with the backend sentence', () async {
      final failure = await sponsorFailure(
        _dioError(
          409,
          body: <String, dynamic>{
            'title': 'This product is already being sponsored.',
            'errorCode': 'state.conflict',
          },
        ),
      );

      expect(isSponsorshipConflict(failure), isTrue);
      expect(
        sponsoredProductsErrorMessage(failure),
        'This product is already being sponsored.',
      );
    });

    test('a 409 without a body still reads as a conflict', () async {
      final failure = await sponsorFailure(_dioError(409));

      expect(isSponsorshipConflict(failure), isTrue);
      expect(
        sponsoredProductsErrorMessage(failure),
        sponsorshipConflictFallbackMessage,
      );
    });

    test('a pause 404 maps to notFound', () async {
      when(
        () => remote.pause(
          productId: any(named: 'productId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(_dioError(404));

      final result = await repo().pause(_productId);

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('a 5xx maps to serverUnavailable', () async {
      when(() => remote.getSponsoredListings()).thenThrow(_dioError(503));

      final result = await repo().getSponsoredListings();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.serverUnavailable(),
      );
    });

    test(
      'offline returns noInternetConnection without calling the API',
      () async {
        final result = await repo(connected: false).getSponsoredListings();

        expect(
          result.getLeft().toNullable(),
          const NetworkExceptions.noInternetConnection(),
        );
        verifyNever(() => remote.getSponsoredListings());
      },
    );

    test('a malformed payload maps to unexpectedError', () async {
      when(
        () => remote.getSponsoredListings(),
      ).thenThrow(const FormatException('bad json'));

      final result = await repo().getSponsoredListings();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });
  });
}
