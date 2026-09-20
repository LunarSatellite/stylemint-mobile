import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_unit_claims_card.dart';

/// Records the path asked for and answers with a canned body.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.body) : super(dio: Dio());

  final Object? body;
  final List<String> paths = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    paths.add(uri);
    if (body is Exception) throw body! as Exception;
    return body;
  }
}

const _bindingId = '11111111-2222-3333-4444-555555555555';

void main() {
  Future<_RecordingApiClient> pump(
    WidgetTester tester,
    Object? body, {
    Size surface = const Size(400, 900),
    double textScale = 1,
  }) async {
    final client = _RecordingApiClient(body);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: surface,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: VendorUnitClaimsCard(unitMarkerBindingId: _bindingId),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return client;
  }

  testWidgets('asks the vendor-scoped route for this binding', (tester) async {
    final client = await pump(tester, <dynamic>[]);

    expect(client.paths, [
      '/v1/vendor/warranties/units/$_bindingId/claims',
    ]);
  });

  /// The route answers the same empty list for a binding that does not exist,
  /// one belonging to another seller, and this seller's own unclaimed unit.
  /// The card must not turn that silence into a claim about which case it is.
  testWidgets('an empty answer says only that there are no claims', (
    tester,
  ) async {
    await pump(tester, <dynamic>[]);

    expect(find.text(VendorUnitClaimsCard.emptyBody), findsOneWidget);
    expect(find.textContaining('no such'), findsNothing);
    expect(find.textContaining('another seller'), findsNothing);
    expect(find.textContaining('not your'), findsNothing);
  });

  testWidgets('lists a claim with its state and filing date', (tester) async {
    await pump(tester, <dynamic>[
      {
        'id': 'claim-1',
        'claimNumber': 'SM-W-20260901-ABCDEF',
        'state': 1,
        'description': 'Zip sheared.',
        'submittedUtc': '2026-09-01T00:00:00Z',
        'unitMarkerBindingId': _bindingId,
      },
    ]);

    expect(find.text('SM-W-20260901-ABCDEF'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Zip sheared.'), findsOneWidget);
  });

  testWidgets('a superseded binding reads as corrected, not hidden', (
    tester,
  ) async {
    await pump(tester, <dynamic>[
      {
        'id': 'claim-1',
        'claimNumber': 'SM-W-20260902-BCDEFA',
        'state': 1,
        'description': 'Seam split.',
        'submittedUtc': '2026-09-02T00:00:00Z',
        'unitMarkerBindingId': 'binding-old',
        'unit': {
          'bindingId': 'binding-old',
          'markerReference': 'UM7ZK3Q8R2VD',
          'isLive': false,
          'supersededUtc': '2026-09-16T00:00:00Z',
          'supersededByBindingId': 'binding-new',
        },
      },
    ]);

    // Present, and named as a correction rather than dropped or silently
    // redirected to the successor.
    expect(find.text('SM-W-20260902-BCDEFA'), findsOneWidget);
    expect(
      find.textContaining('has since been corrected').evaluate().isNotEmpty ||
          find.textContaining('corrected on').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.textContaining('still names that binding'), findsOneWidget);
  });

  testWidgets('a failure offers a retry and claims nothing about the unit', (
    tester,
  ) async {
    await pump(tester, Exception('boom'));

    expect(find.text(VendorUnitClaimsCard.failedBody), findsOneWidget);
    expect(find.text(VendorUnitClaimsCard.retryLabel), findsOneWidget);
    expect(find.text(VendorUnitClaimsCard.emptyBody), findsNothing);
  });

  testWidgets('no overflow at 320dp with text at 1.3x', (tester) async {
    await pump(
      tester,
      <dynamic>[
        {
          'id': 'claim-1',
          'claimNumber': 'SM-W-20260902-BCDEFA',
          'state': 4,
          'description': 'Seam split along the shoulder after two washes.',
          'submittedUtc': '2026-09-02T00:00:00Z',
          'unit': {
            'bindingId': 'binding-old',
            'markerReference': 'UM7ZK3Q8R2VD',
            'isLive': false,
            'supersededUtc': '2026-09-16T00:00:00Z',
          },
        },
      ],
      surface: const Size(320, 1400),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
