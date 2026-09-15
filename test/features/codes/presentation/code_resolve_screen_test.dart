import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/repositories/codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/screens/code_resolve_screen.dart';
import 'package:stylemint_mobile_frontend/features/codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class _MockCodesRepository extends Mock implements CodesRepository {}

void main() {
  late _MockCodesRepository repository;

  setUpAll(() => registerFallbackValue(CodeScanVia.link));

  setUp(() => repository = _MockCodesRepository());

  void stub(Either<NetworkExceptions, ResolvedCode> result) {
    when(
      () => repository.resolve(any(), any()),
    ).thenAnswer((_) async => result);
  }

  Future<void> pump(
    WidgetTester tester,
    String location, {
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: RouteNames.styleMintCode,
          builder: (_, state) => CodeResolveScreen(
            code: state.pathParameters['code']!,
            via: CodeScanVia.parse(state.uri.queryParameters['via']),
          ),
        ),
        GoRoute(
          path: RouteNames.inStoreProduct,
          builder: (_, state) {
            final query = state.uri.queryParameters;
            return Text(
              'product ${state.pathParameters['productId']} in '
              '${query[InStoreQuery.store]}, ${query[InStoreQuery.city]} '
              'store ${query[InStoreQuery.storeId]} '
              'code ${query[InStoreQuery.code]}',
            );
          },
        ),
        GoRoute(
          path: RouteNames.inStoreStore,
          builder: (_, state) => Text(
            'store ${state.pathParameters['storeId']} '
            '${state.uri.queryParameters[InStoreQuery.store]} by '
            '${state.uri.queryParameters[InStoreQuery.vendor]}',
          ),
        ),
        GoRoute(
          path: RouteNames.creatorProfile,
          builder: (_, state) {
            final args = state.extra! as CreatorProfileArgs;
            return Text(
              'profile ${state.pathParameters['accountId']} '
              '${args.displayName} @${args.handle}',
            );
          },
        ),
        GoRoute(path: RouteNames.home, builder: (_, _) => const Text('home')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [codesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('shows the StyleMint loader while the code resolves', (
    tester,
  ) async {
    final pending = Completer<Either<NetworkExceptions, ResolvedCode>>();
    when(
      () => repository.resolve(any(), any()),
    ).thenAnswer((_) => pending.future);

    await pump(tester, '/c/ABCD2345?via=Qr', settle: false);

    expect(find.byType(SmBrandLoader), findsOneWidget);
    expect(find.text(CodeResolveScreen.openingLabel), findsOneWidget);

    pending.complete(left(const NetworkExceptions.notFound()));
    await tester.pumpAndSettle();
    expect(find.byType(SmBrandLoader), findsNothing);
  });

  testWidgets('a product tag opens the in-store product screen', (
    tester,
  ) async {
    stub(
      right(
        const ResolvedCode(
          code: 'ABCD2345',
          kind: CodeKind.productTag,
          productId: 'p-1',
          storeId: 's-1',
          storeName: 'Mint Thamel',
          storeCity: 'Kathmandu',
        ),
      ),
    );

    await pump(tester, '/c/abcd2345?via=Qr');

    expect(
      find.text(
        'product p-1 in Mint Thamel, Kathmandu store s-1 code ABCD2345',
      ),
      findsOneWidget,
    );
    verify(() => repository.resolve('ABCD2345', CodeScanVia.qr)).called(1);
  });

  testWidgets('a store code from an NFC tag opens the store screen', (
    tester,
  ) async {
    stub(
      right(
        const ResolvedCode(
          code: 'ABCD2345',
          kind: CodeKind.store,
          storeId: 's-1',
          storeName: 'Mint Thamel',
          vendorDisplayName: 'Mint Studio',
        ),
      ),
    );

    await pump(tester, '/c/ABCD2345?via=Nfc');

    expect(find.text('store s-1 Mint Thamel by Mint Studio'), findsOneWidget);
    verify(() => repository.resolve('ABCD2345', CodeScanVia.nfc)).called(1);
  });

  testWidgets('a profile code opens the person, counted as a link', (
    tester,
  ) async {
    stub(
      right(
        const ResolvedCode(
          code: '7K9M2PQR',
          kind: CodeKind.profile,
          accountId: 'a-1',
          displayName: 'Asha Rai',
          handle: 'asha',
        ),
      ),
    );

    await pump(tester, '/c/7K9M2PQR');

    expect(find.text('profile a-1 Asha Rai @asha'), findsOneWidget);
    verify(() => repository.resolve('7K9M2PQR', CodeScanVia.link)).called(1);
  });

  testWidgets('an unknown or revoked code says so and offers home', (
    tester,
  ) async {
    stub(left(const NetworkExceptions.notFound()));

    await pump(tester, '/c/ABCD2345?via=Qr');

    expect(find.text(CodeResolveScreen.notActiveTitle), findsOneWidget);
    await tester.tap(find.text(CodeResolveScreen.homeLabel));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a code pointing at nothing openable is not active', (
    tester,
  ) async {
    stub(
      right(const ResolvedCode(code: 'ABCD2345', kind: CodeKind.productTag)),
    );

    await pump(tester, '/c/ABCD2345');

    expect(find.text(CodeResolveScreen.notActiveTitle), findsOneWidget);
  });

  testWidgets('a malformed code never reaches the backend', (tester) async {
    await pump(tester, '/c/ABCI2345?via=Qr');

    expect(find.text(CodeResolveScreen.notActiveTitle), findsOneWidget);
    verifyNever(() => repository.resolve(any(), any()));
  });

  testWidgets('a network failure can be retried', (tester) async {
    final answers = <Either<NetworkExceptions, ResolvedCode>>[
      left(const NetworkExceptions.noInternetConnection()),
      right(
        const ResolvedCode(
          code: 'ABCD2345',
          kind: CodeKind.store,
          storeId: 's-9',
        ),
      ),
    ];
    when(
      () => repository.resolve(any(), any()),
    ).thenAnswer((_) async => answers.removeAt(0));

    await pump(tester, '/c/ABCD2345?via=Qr');

    expect(find.text(CodeResolveScreen.failedTitle), findsOneWidget);
    expect(find.text('No internet connection.'), findsOneWidget);

    await tester.tap(find.text(CodeResolveScreen.retryLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('store s-9'), findsOneWidget);
  });
}
