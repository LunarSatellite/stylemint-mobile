import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/datasources/vendor_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/onboarding/service_licence_uploader.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/onboarding/vendor_apply_service_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';

import 'service_fixtures.dart';

class _FakeUploader implements ServiceLicenceUploader {
  int uploads = 0;

  @override
  Future<String?> pick() async => '/photos/licence.jpg';

  @override
  Future<Either<ServiceFailure, UploadedLicence>> upload(
    String filePath,
  ) async {
    uploads++;
    return right((reference: 'blob://kyc/abc', fileName: 'licence.jpg'));
  }
}

VendorApplyDraft _draft({BusinessType type = BusinessType.limitedLiabilityCompany}) =>
    VendorApplyDraft(
      accountId: 'acc-1',
      brandName: 'Himalayan Bank',
      legalBusinessName: 'Himalayan Bank Ltd',
      businessType: type,
      taxId: '300000001',
      businessRegistrationNumber: 'REG-1',
      countryRegion: 'Nepal',
      streetAddress: 'Kamaladi',
      city: 'Kathmandu',
      country: 'Nepal',
      zipCode: '44600',
      state: 'Bagmati',
    );

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  VendorApplyDraft? draft,
  _FakeUploader? uploader,
}) async {
  tallPhone(tester);
  final container = ProviderContainer(
    overrides: [
      serviceLicenceUploaderProvider.overrideWithValue(
        uploader ?? _FakeUploader(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(vendorApplyDraftProvider.notifier).draft = draft ?? _draft();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const VendorApplyServiceScreen(),
      ),
      GoRoute(
        path: '/vendor/apply/step2',
        builder: (_, _) => const Text('step 2 page'),
      ),
      GoRoute(path: '/vendor/apply', builder: (_, _) => const Text('step 1')),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
  return container;
}

bool _enabled(WidgetTester tester) {
  final button = tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(VendorApplyServiceScreen.continueKey),
      matching: find.byType(FilledButton),
    ),
  );
  return button.onPressed != null;
}

void main() {
  group('the application form', () {
    test('business types use the backend codes', () {
      expect(BusinessType.limitedLiabilityCompany.code, 3);
      expect(BusinessType.corporation.code, 4);
      expect(BusinessType.partnership.code, 5);
      expect(BusinessType.fromCode(3), BusinessType.limitedLiabilityCompany);
    });

    test('a bank draft carries its category and licence to the submission', () {
      final draft = _draft().withService(
        serviceCategory: 3,
        licenceNumber: 'NRB-A-012',
        licenceExpiresOn: DateTime(2028, 7, 15),
        licenceDocumentRef: 'blob://kyc/abc',
      );
      final form = draft.toForm();
      expect(form.serviceCategory, 3);
      expect(form.isServiceVendor, isTrue);
      expect(form.licenceDocumentRef, 'blob://kyc/abc');
      expect(VendorRemoteDataSource.serviceStepBody(form), {
        'serviceCategory': 3,
        'licenceNumber': 'NRB-A-012',
        'licenceIssuer': null,
        'licenceExpiresOn': '2028-07-15',
      });
    });

    test('switching back to products clears the licence', () {
      final draft = _draft()
          .withService(serviceCategory: 3, licenceNumber: 'NRB-A-012')
          .withService(serviceCategory: 0, licenceNumber: 'NRB-A-012');
      expect(draft.serviceCategory, 0);
      expect(draft.licenceNumber, isNull);
      expect(draft.toForm().isServiceVendor, isFalse);
    });

    test('a product seller\'s draft is unchanged', () {
      final form = _draft().toForm();
      expect(form.serviceCategory, 0);
      expect(form.licenceNumber, isNull);
    });
  });

  group('service step', () {
    testWidgets('products is the default and goes straight on', (
      tester,
    ) async {
      final container = await _pump(tester);
      expect(find.text('What kind of business is it?'), findsOneWidget);
      expect(find.byKey(VendorApplyServiceScreen.licenceNumberKey), findsNothing);
      expect(_enabled(tester), isTrue);

      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.continueKey),
      );
      expect(find.text('step 2 page'), findsOneWidget);
      expect(container.read(vendorApplyDraftProvider)?.serviceCategory, 0);
    });

    testWidgets('a bank needs its NRB licence number', (tester) async {
      final container = await _pump(tester);
      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.categoryKey(ServiceCategory.bank)),
      );
      expect(find.text('NRB licence number'), findsOneWidget);
      expect(_enabled(tester), isFalse);

      await tester.enterText(
        find.byKey(VendorApplyServiceScreen.licenceNumberKey),
        'NRB-A-012',
      );
      await tester.pump();
      expect(_enabled(tester), isTrue);

      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.continueKey),
      );
      expect(find.text('step 2 page'), findsOneWidget);
      final draft = container.read(vendorApplyDraftProvider)!;
      expect(draft.serviceCategory, ServiceCategory.bank.wire);
      expect(draft.licenceNumber, 'NRB-A-012');
      expect(draft.brandName, 'Himalayan Bank', reason: 'step 1 kept');
    });

    testWidgets('a bank must be a limited company or a corporation', (
      tester,
    ) async {
      await _pump(tester, draft: _draft(type: BusinessType.partnership));
      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.categoryKey(ServiceCategory.bank)),
      );
      await tester.enterText(
        find.byKey(VendorApplyServiceScreen.licenceNumberKey),
        'NRB-A-012',
      );
      await tester.pump();
      expect(
        find.byKey(VendorApplyServiceScreen.businessTypeWarningKey),
        findsOneWidget,
      );
      expect(_enabled(tester), isFalse);
    });

    testWidgets('a hotel\'s licence is optional, and the certificate uploads',
        (tester) async {
      final uploader = _FakeUploader();
      final container = await _pump(tester, uploader: uploader);
      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.categoryKey(ServiceCategory.hotel)),
      );
      expect(find.text('Tourism licence number (optional)'), findsOneWidget);
      expect(_enabled(tester), isTrue);

      await tapAndSettle(tester, find.byKey(VendorApplyServiceScreen.uploadKey));
      expect(uploader.uploads, 1);
      expect(find.text('Replace certificate (licence.jpg)'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(VendorApplyServiceScreen.continueKey),
      );
      final draft = container.read(vendorApplyDraftProvider)!;
      expect(draft.serviceCategory, ServiceCategory.hotel.wire);
      expect(draft.licenceNumber, isNull);
      expect(draft.licenceDocumentRef, 'blob://kyc/abc');
      expect(draft.licenceDocumentName, 'licence.jpg');
    });
  });
}
