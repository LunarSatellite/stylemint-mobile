import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/datasources/tips_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getResponse, this.postResponse}) : super(dio: Dio());

  final dynamic getResponse;
  final dynamic postResponse;
  String? getUri;
  String? postUri;
  Map<String, dynamic>? getQuery;
  dynamic postData;
  Options? postOptions;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    getQuery = queryParameters;
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    postOptions = options;
    return postResponse;
  }
}

void main() {
  test('parses cursor-paged tip history and counterpart data', () async {
    final api = _FakeApiClient(
      getResponse: {
        'items': [
          {
            'id': 'tip-id',
            'senderId': 'sender-id',
            'senderName': 'Mina',
            'senderAvatarUrl': null,
            'receiverId': 'creator-profile-id',
            'receiverName': 'Asha',
            'receiverAvatarUrl': '',
            'amount': {'amount': 125.0, 'currency': 'NPR'},
            'reelId': null,
            'createdAt': '2026-09-11T05:00:00Z',
          },
        ],
        'totalCount': 1,
        'nextCursor': null,
        'pageSize': 50,
      },
    );

    final tips = await TipsRemoteDataSource(
      apiClient: api,
    ).getTipHistory(type: 'received');

    expect(api.getUri, '/v1/tips/history');
    expect(api.getQuery, {'type': 'received', 'pageSize': 50});
    expect(tips, hasLength(1));
    expect(tips.single.senderName, 'Mina');
    expect(tips.single.receiverName, 'Asha');
    expect(tips.single.amount, 125);
    expect(tips.single.senderAvatarUrl, isEmpty);
  });

  test('parses canonical money objects from tip balance', () async {
    final api = _FakeApiClient(
      getResponse: {
        'availableBalance': {'amount': 100.0, 'currency': 'NPR'},
        'totalReceived': {'amount': 100.0, 'currency': 'NPR'},
        'totalSent': {'amount': 25.0, 'currency': 'NPR'},
        'pendingBalance': {'amount': 30.0, 'currency': 'NPR'},
      },
    );

    final balance = await TipsRemoteDataSource(
      apiClient: api,
    ).getBalance();

    expect(api.getUri, '/v1/tips/balance');
    expect(api.getQuery, {'currency': 'NPR'});
    expect(balance.availableAmount, 100);
    expect(balance.totalSentAmount, 25);
    expect(balance.pendingAmount, 30);
  });

  test('uses the secured tip initiation contract', () async {
    final api = _FakeApiClient(
      postResponse: {
        'id': 'tip-id',
        'fromAccountId': 'sender-id',
        'toCreatorProfileId': 'creator-profile-id',
        'amount': {'amount': 50.0, 'currency': 'NPR'},
        'reelId': null,
        'initiatedUtc': '2026-09-11T05:00:00Z',
      },
    );

    await TipsRemoteDataSource(apiClient: api).sendTip(
      creatorProfileId: 'creator-profile-id',
      amount: 50,
      currency: 'NPR',
      paymentIntentId: 'payment-intent-id',
      idempotencyKey: 'tip-key',
    );

    expect(api.postUri, '/v1/tips');
    expect(api.postData, {
      'toCreatorProfileId': 'creator-profile-id',
      'amountValue': 50.0,
      'currency': 'NPR',
      'paymentIntentId': 'payment-intent-id',
    });
    expect(api.postOptions?.headers?['Idempotency-Key'], 'tip-key');
  });
}
