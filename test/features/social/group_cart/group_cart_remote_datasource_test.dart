import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/datasources/group_cart_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.getResponse,
    this.postResponse,
  }) : super(dio: Dio());

  final dynamic getResponse;
  final dynamic postResponse;
  String? getUri;
  String? postUri;
  dynamic postData;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
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
    return postResponse;
  }
}

Map<String, dynamic> _cartShareJson() => <String, dynamic>{
  'id': '4d8997a9-6069-4fc8-84b8-da3ac19b8bc5',
  'cartId': 'ca75ec52-badb-43a5-8734-a6da8740ddc2',
  'ownerAccountId': 'ca75ec52-badb-43a5-8734-a6da8740ddc2',
  'state': 1,
  'memberCount': 1,
  'createdUtc': '2026-09-11T00:00:00Z',
  'updatedUtc': '2026-09-11T00:00:00Z',
};

void main() {
  test('parses the cursor-paged CartShare list contract', () async {
    final api = _FakeApiClient(
      getResponse: <String, dynamic>{
        'items': <dynamic>[_cartShareJson()],
        'totalCount': 1,
        'nextCursor': null,
        'pageSize': 20,
      },
    );
    final datasource = GroupCartRemoteDataSource(apiClient: api);

    final carts = await datasource.getGroupCarts();

    expect(api.getUri, '/v1/cart-shares');
    expect(carts, hasLength(1));
    expect(carts.single.name, 'Group Cart');
    expect(
      carts.single.ownerId,
      'ca75ec52-badb-43a5-8734-a6da8740ddc2',
    );
    expect(carts.single.status, 'active');
  });

  test('creates the authenticated account cart with an empty body', () async {
    final api = _FakeApiClient(postResponse: _cartShareJson());
    final datasource = GroupCartRemoteDataSource(apiClient: api);

    final cart = await datasource.createGroupCart('idempotency-key');

    expect(api.postUri, '/v1/cart-shares');
    expect(api.postData, isEmpty);
    expect(cart.id, '4d8997a9-6069-4fc8-84b8-da3ac19b8bc5');
  });

  test('invites a friend and returns the one-time token', () async {
    final api = _FakeApiClient(
      postResponse: <String, dynamic>{'token': 'invite-token'},
    );
    final datasource = GroupCartRemoteDataSource(apiClient: api);

    final token = await datasource.inviteToGroupCart(
      'cart-share-id',
      'friend-account-id',
      'idempotency-key',
    );

    expect(api.postUri, '/v1/cart-shares/cart-share-id/invite');
    expect(api.postData, <String, dynamic>{
      'invitedAccountId': 'friend-account-id',
      'proposedRole': 2,
    });
    expect(token, 'invite-token');
  });
}
