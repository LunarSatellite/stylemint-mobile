import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/repositories/vendor_emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/vendor_emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/notifiers/vendor_emi_terms_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockVendorEmiRepository extends Mock implements VendorEmiRepository {}

VendorEmiTerms _terms({
  bool enabled = false,
  int min = 20,
  int effective = 20,
  List<int> tenures = const [],
  int eligible = 2,
}) => VendorEmiTerms(
  productId: 'p1',
  productName: 'Pashmina overcoat',
  enabled: enabled,
  minDownPaymentPercent: min,
  effectiveMinDownPaymentPercent: effective,
  tenures: tenures,
  eligibleVariantCount: eligible,
  minimumPrice: const Money(amount: 20000, currency: 'NPR'),
);

String _message(String code) =>
    vendorEmiErrorMessage(EmiFailure(EmiFailureKind.rejected, code: code));

void main() {
  group('validateVendorEmiTerms', () {
    String? validate({
      bool enabled = true,
      int min = 30,
      List<int> tenures = const [3, 6],
      int eligible = 1,
    }) => validateVendorEmiTerms(
      enabled: enabled,
      minDownPaymentPercent: min,
      tenures: tenures,
      eligibleVariantCount: eligible,
    );

    test('accepts terms the server accepts', () {
      expect(validate(), isNull);
      expect(validate(min: 20, tenures: const [3, 6, 9, 12]), isNull);
      expect(validate(min: 90, tenures: const [12]), isNull);
    });

    test('down payment outside 20–90 or off the 5 % step', () {
      final expected = _message(VendorEmiErrorCode.downPaymentOutOfRange);
      expect(validate(min: 15), expected);
      expect(validate(min: 95), expected);
      expect(validate(min: 33), expected);
      expect(expected, contains('between 20% and 90%'));
    });

    test('no tenure, or one the contract does not allow', () {
      final expected = _message(VendorEmiErrorCode.invalidTenure);
      expect(validate(tenures: const []), expected);
      expect(validate(tenures: const [3, 24]), expected);
      expect(expected, contains('3, 6, 9 or 12'));
    });

    test('switching on with no variant at the minimum price', () {
      expect(
        validate(eligible: 0),
        _message(VendorEmiErrorCode.priceBelowMinimum),
      );
      expect(validate(eligible: 0), contains('Rs 20,000'));
      // Switching off is always allowed.
      expect(validate(enabled: false, eligible: 0), isNull);
    });
  });

  test('every emi_terms and emi_settings code has its own sentence', () {
    final messages = {
      for (final code in const [
        VendorEmiErrorCode.priceBelowMinimum,
        VendorEmiErrorCode.downPaymentOutOfRange,
        VendorEmiErrorCode.invalidTenure,
        VendorEmiErrorCode.interestNotAllowed,
        VendorEmiErrorCode.approvalModeNotAllowed,
        VendorEmiErrorCode.exposureAboveMaximum,
      ])
        code: _message(code),
    };
    expect(messages.values.toSet(), hasLength(messages.length));
    expect(
      messages[VendorEmiErrorCode.interestNotAllowed],
      contains('interest-free'),
    );
    expect(
      messages[VendorEmiErrorCode.approvalModeNotAllowed],
      contains('your approval'),
    );
    expect(
      vendorEmiErrorMessage(
        const EmiFailure(
          EmiFailureKind.rejected,
          code: VendorEmiErrorCode.exposureAboveMaximum,
        ),
        maxExposureLimit: const Money(amount: 500000, currency: 'NPR'),
      ),
      contains('Rs 500,000'),
    );
    expect(
      vendorEmiErrorMessage(const EmiFailure(EmiFailureKind.server)),
      contains('temporarily unavailable'),
    );
  });

  group('previewEffectiveMinDownPercent', () {
    test('applies the commission floor the server revealed', () {
      // Saved 20 %, effective 30 %: the commission needs 30 %.
      expect(
        previewEffectiveMinDownPercent(
          selected: 25,
          savedMinDownPaymentPercent: 20,
          savedEffectiveMinDownPaymentPercent: 30,
        ),
        30,
      );
      expect(
        previewEffectiveMinDownPercent(
          selected: 40,
          savedMinDownPaymentPercent: 20,
          savedEffectiveMinDownPaymentPercent: 30,
        ),
        40,
      );
    });

    test('without a revealed floor, the vendor’s choice stands', () {
      expect(
        previewEffectiveMinDownPercent(
          selected: 25,
          savedMinDownPaymentPercent: 40,
          savedEffectiveMinDownPaymentPercent: 40,
        ),
        25,
      );
    });
  });

  group('VendorEmiTermsNotifier', () {
    late _MockVendorEmiRepository repository;

    setUpAll(() => registerFallbackValue(<int>[]));
    setUp(() => repository = _MockVendorEmiRepository());

    VendorEmiTermsNotifier notifier() {
      final n = VendorEmiTermsNotifier(repository, 'p1');
      addTearDown(n.dispose);
      return n;
    }

    void saveAnswers(Either<EmiFailure, VendorEmiTerms> answer) => when(
      () => repository.saveTerms(
        any(),
        enabled: any(named: 'enabled'),
        minDownPaymentPercent: any(named: 'minDownPaymentPercent'),
        tenures: any(named: 'tenures'),
      ),
    ).thenAnswer((_) async => answer);

    test(
      'a never-configured listing opens off, clean, with every tenure',
      () async {
        when(
          () => repository.getTerms('p1'),
        ).thenAnswer((_) async => right(_terms()));
        final n = notifier();
        await n.load();

        expect(n.state.enabled, isFalse);
        expect(n.state.tenures, [3, 6, 9, 12]);
        expect(n.state.minDownPaymentPercent, 20);
        expect(n.state.isDirty, isFalse);
      },
    );

    test('a 404 hides the section', () async {
      when(() => repository.getTerms('p1')).thenAnswer(
        (_) async => left(const EmiFailure(EmiFailureKind.notFound)),
      );
      final n = notifier();
      await n.load();
      expect(n.state.isUnavailable, isTrue);
    });

    test('editing makes the draft dirty; tenures stay sorted', () async {
      when(
        () => repository.getTerms('p1'),
      ).thenAnswer((_) async => right(_terms(tenures: const [6])));
      final n = notifier();
      await n.load();

      n
        ..setEnabled(true)
        ..toggleTenure(3)
        ..toggleTenure(24)
        ..setMinDownPaymentPercent(33);

      expect(n.state.isDirty, isTrue);
      expect(n.state.tenures, [3, 6]);
      expect(n.state.minDownPaymentPercent, 35);
    });

    test('an invalid draft is refused without a request', () async {
      when(
        () => repository.getTerms('p1'),
      ).thenAnswer((_) async => right(_terms(eligible: 0)));
      final n = notifier();
      await n.load();
      n.setEnabled(true);

      expect(await n.save(), isFalse);
      expect(n.state.error, contains('Rs 20,000'));
      verifyNever(
        () => repository.saveTerms(
          any(),
          enabled: any(named: 'enabled'),
          minDownPaymentPercent: any(named: 'minDownPaymentPercent'),
          tenures: any(named: 'tenures'),
        ),
      );
    });

    test('a refused save shows the code’s sentence', () async {
      when(
        () => repository.getTerms('p1'),
      ).thenAnswer((_) async => right(_terms()));
      saveAnswers(
        left(
          const EmiFailure(
            EmiFailureKind.rejected,
            code: VendorEmiErrorCode.interestNotAllowed,
          ),
        ),
      );
      final n = notifier();
      await n.load();
      n.setEnabled(true);

      expect(await n.save(), isFalse);
      expect(n.state.saving, isFalse);
      expect(n.state.error, _message(VendorEmiErrorCode.interestNotAllowed));
    });

    test('a saved draft takes the server’s terms and is clean', () async {
      when(
        () => repository.getTerms('p1'),
      ).thenAnswer((_) async => right(_terms()));
      saveAnswers(
        right(
          _terms(enabled: true, min: 20, effective: 30, tenures: const [3, 6]),
        ),
      );
      final n = notifier();
      await n.load();
      n
        ..setEnabled(true)
        ..toggleTenure(9)
        ..toggleTenure(12);

      expect(await n.save(), isTrue);
      expect(n.state.justSaved, isTrue);
      expect(n.state.isDirty, isFalse);
      expect(n.state.saved?.minimumWasRaised, isTrue);
      expect(n.state.previewEffectiveMin, 30);
      verify(
        () => repository.saveTerms(
          'p1',
          enabled: true,
          minDownPaymentPercent: 20,
          tenures: [3, 6],
        ),
      ).called(1);
    });
  });
}
