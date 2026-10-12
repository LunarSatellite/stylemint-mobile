import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/emi_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/emi_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/data/models/customer_kyc_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/models/vendor_emi_json.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Map<String, dynamic> _money(num amount) => <String, dynamic>{
  'amount': amount,
  'currency': 'NPR',
};

/// The product detail payload, abridged, with two variants either side of
/// the NPR 20,000 minimum.
Map<String, dynamic> _product({Object? emi = _absent, bool flags = true}) => {
  'id': 'p1',
  'name': 'Pashmina overcoat',
  'variants': [
    {
      'id': 'v-cheap',
      'sku': 'S',
      'priceAmount': 12000,
      'priceCurrency': 'NPR',
      if (flags) 'emiEligible': false,
    },
    {
      'id': 'v-dear',
      'sku': 'L',
      'priceAmount': 25000,
      'priceCurrency': 'NPR',
      if (flags) 'emiEligible': true,
    },
  ],
  if (!identical(emi, _absent)) 'emi': emi,
};

const _absent = Object();

Map<String, dynamic> _emiBlock({bool available = true}) => {
  'available': available,
  'fromMonthly': _money(2917),
  'minDownPaymentPercent': 30,
  'tenures': [6, 3, 7],
  'interestRatePercentMonthly': 0,
  'minimumPrice': _money(20000),
};

Map<String, dynamic> _quote() => {
  'variantId': 'v-dear',
  'productId': 'p1',
  'price': _money(25000),
  'downPaymentPercent': 30,
  'downPayment': _money(7500),
  'financedAmount': _money(17500),
  'tenureMonths': 6,
  'monthlyInstallment': _money(2917),
  'lastInstallment': _money(2915),
  'interestTotal': _money(0),
  'totalPayable': _money(25000),
  'schedule': [
    for (var n = 6; n >= 1; n--)
      {'number': n, 'amount': _money(n == 6 ? 2915 : 2917)},
  ],
  'constraints': {
    'minDownPaymentPercent': 30,
    'maxDownPaymentPercent': 90,
    'tenures': [3, 6],
  },
};

void main() {
  group('product detail emi', () {
    test('absent (a server older than EMI) is no offer', () {
      expect(readProductEmiOffer(_product()), isNull);
    });

    test('null (EMI off, or nothing qualifies) is no offer', () {
      expect(readProductEmiOffer(_product(emi: null)), isNull);
    });

    test('available: false is no offer', () {
      expect(
        readProductEmiOffer(_product(emi: _emiBlock(available: false))),
        isNull,
      );
    });

    test('a block with no usable tenure is no offer', () {
      expect(
        readProductEmiOffer(
          _product(emi: {..._emiBlock(), 'tenures': <int>[]}),
        ),
        isNull,
      );
    });

    test('reads the block and each variant’s emiEligible', () {
      final offer = readProductEmiOffer(_product(emi: _emiBlock()))!;

      expect(offer.minDownPaymentPercent, 30);
      // 7 is not a tenure the contract allows; the rest come back sorted.
      expect(offer.tenures, [3, 6]);
      expect(offer.fromMonthly, const Money(amount: 2917, currency: 'NPR'));
      expect(offer.minimumPrice?.amount, 20000);
      expect(offer.isEligible('v-dear'), isTrue);
      expect(offer.isEligible('v-cheap'), isFalse);
      expect(offer.isEligible('missing'), isFalse);
      expect(offer.priceOf('v-cheap'), isNull);
      expect(offer.fromMonthlyFor('v-dear'), offer.fromMonthly);
    });

    test('a variant without emiEligible is judged by price against the '
        'minimum', () {
      final offer = readProductEmiOffer(
        _product(emi: _emiBlock(), flags: false),
      )!;
      expect(offer.isEligible('v-dear'), isTrue);
      expect(offer.isEligible('v-cheap'), isFalse);
    });

    test('no eligible variant at all is no offer', () {
      final product = _product(emi: _emiBlock());
      for (final variant in product['variants'] as List) {
        (variant as Map<String, dynamic>)['emiEligible'] = false;
      }
      expect(readProductEmiOffer(product), isNull);
    });
  });

  test('EmiQuoteDto reads every figure and orders the schedule', () {
    final quote = readEmiQuote(_quote());

    expect(quote.variantId, 'v-dear');
    expect(quote.downPayment.amount, 7500);
    expect(quote.financedAmount.amount, 17500);
    expect(quote.monthlyInstallment.amount, 2917);
    expect(quote.lastInstallment.amount, 2915);
    expect(quote.interestTotal.amount, 0);
    expect(quote.totalPayable.amount, 25000);
    expect([for (final i in quote.schedule) i.number], [1, 2, 3, 4, 5, 6]);
    expect(quote.schedule.last.amount.amount, 2915);
    expect(quote.constraints?.tenures, [3, 6]);
    expect(
      quote.matches(
        variantId: 'v-dear',
        downPaymentPercent: 30,
        tenureMonths: 6,
      ),
      isTrue,
    );
    expect(
      quote.matches(
        variantId: 'v-dear',
        downPaymentPercent: 35,
        tenureMonths: 6,
      ),
      isFalse,
    );
  });

  group('eligibility', () {
    EmiEligibility read(Map<String, dynamic> json) => readEmiEligibility(json);

    test('eligible buyers are told EMI checkout is coming', () {
      final e = read({
        'kycTier': 2,
        'kycStatus': 'Approved',
        'eligible': true,
        'reasons': <String>[],
        'band': null,
      });
      expect(e.kycStatus, KycStatus.approved);
      expect(e.band, isNull);
      expect(e.cta, EmiCta.eligible);
    });

    test('each reason picks its button', () {
      EmiCta cta(String reason, String status) => read({
        'kycTier': 0,
        'kycStatus': status,
        'eligible': false,
        'reasons': [reason],
      }).cta;

      expect(cta('kyc_required', 'None'), EmiCta.getVerified);
      expect(cta('kyc_rejected', 'Rejected'), EmiCta.getVerified);
      expect(cta('kyc_in_review', 'UnderReview'), EmiCta.inReview);
    });

    test('an unknown reason falls back on the KYC status', () {
      final e = read({
        'kycTier': 0,
        'kycStatus': 'Submitted',
        'eligible': false,
        'reasons': ['band_d'],
      });
      expect(e.cta, EmiCta.inReview);
    });
  });

  group('CustomerKycDto', () {
    test('reads a rejected session with its documents', () {
      final kyc = readCustomerKyc({
        'tier': 0,
        'status': 'Rejected',
        'sessionId': 's1',
        'documentType': 'Citizenship',
        'documents': [
          {
            'id': 'd1',
            'kind': 'CitizenshipFront',
            'uploadedUtc': '2026-10-09T08:00:00+05:45',
            'thumbnailUrl': null,
          },
          {'id': 'd2', 'kind': 'SomethingNew'},
        ],
        'missingDocuments': ['Selfie', 'Unknown'],
        'rejectionReason': 'The photo is blurred.',
        'canResubmit': true,
        'submittedUtc': '2026-10-08T08:00:00+05:45',
        'reviewedUtc': null,
        'expiresUtc': null,
      });

      expect(kyc.status, KycStatus.rejected);
      expect(kyc.documentType, KycDocumentType.citizenship);
      // An unknown kind is dropped rather than misfiled.
      expect(kyc.documents.single.kind, KycDocumentKind.citizenshipFront);
      expect(kyc.missingDocuments, [KycDocumentKind.selfie]);
      expect(kyc.rejectionReason, 'The photo is blurred.');
      expect(kyc.canStartOrResume, isTrue);
      expect(kyc.isVerified, isFalse);
    });

    test('an unknown status is not mistaken for a known one', () {
      final kyc = readCustomerKyc({'tier': 0, 'status': 'OnHold'});
      expect(kyc.status, KycStatus.unknown);
      expect(kyc.canStartOrResume, isFalse);
    });

    test('UnderReview and Approved tier 2', () {
      expect(
        readCustomerKyc({'status': 'UnderReview'}).status.isInReview,
        isTrue,
      );
      expect(
        readCustomerKyc({'tier': 2, 'status': 'Approved'}).isVerified,
        isTrue,
      );
    });
  });

  group('VendorEmiTermsDto', () {
    test('reads terms with a sample quote', () {
      final terms = readVendorEmiTerms({
        'productId': 'p1',
        'productName': 'Pashmina overcoat',
        'enabled': true,
        'minDownPaymentPercent': 20,
        'effectiveMinDownPaymentPercent': 30,
        'tenures': [3, 6],
        'interestRatePercentMonthly': 0,
        'approvalMode': 'Manual',
        'eligibleVariantCount': 2,
        'minimumPrice': _money(20000),
        'sampleQuote': _quote(),
        'updatedUtc': '2026-10-09T08:00:00Z',
      });

      expect(terms.enabled, isTrue);
      expect(terms.minimumWasRaised, isTrue);
      expect(terms.tenures, [3, 6]);
      expect(terms.sampleQuote?.monthlyInstallment.amount, 2917);
      expect(terms.updatedUtc, isNotNull);
    });

    test('a never-configured product reads as off with defaults', () {
      final terms = readVendorEmiTerms({
        'productId': 'p1',
        'enabled': false,
        'minDownPaymentPercent': 20,
        'effectiveMinDownPaymentPercent': 20,
        'tenures': <int>[],
        'eligibleVariantCount': 0,
        'sampleQuote': null,
        'updatedUtc': null,
      });
      expect(terms.enabled, isFalse);
      expect(terms.sampleQuote, isNull);
      expect(terms.minimumWasRaised, isFalse);
      expect(terms.approvalMode, 'Manual');
    });

    test('the PUT body pins interest to 0 and approval to Manual', () {
      expect(
        vendorEmiTermsBody(
          enabled: true,
          minDownPaymentPercent: 30,
          tenures: const [6, 3],
        ),
        {
          'enabled': true,
          'minDownPaymentPercent': 30,
          'tenures': [3, 6],
          'interestRatePercentMonthly': 0,
          'approvalMode': 'Manual',
        },
      );
    });

    test('settings: a null limit stays null; the ceiling defaults', () {
      final settings = readVendorEmiSettings({'exposureLimit': null});
      expect(settings.exposureLimit, isNull);
      expect(settings.maxExposureLimit.amount, 500000);
      expect(vendorEmiSettingsBody(null), {'exposureLimit': null});
    });
  });

  group('mapEmiFailure', () {
    DioException http(int status, Object? body) => DioException(
      requestOptions: RequestOptions(path: '/v1/emi/quote'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/v1/emi/quote'),
        statusCode: status,
        data: body,
      ),
    );

    test('a 404 keeps its errorCode', () {
      final failure = mapEmiFailure(
        http(404, {'errorCode': 'emi_quote.not_available', 'title': 'x'}),
      );
      expect(failure.kind, EmiFailureKind.notFound);
      expect(failure.code, 'emi_quote.not_available');
    });

    test('documents_missing keeps its missing list', () {
      final failure = mapEmiFailure(
        http(422, {
          'errorCode': 'kyc.documents_missing',
          'detail': 'Missing documents.',
          'missing': ['CitizenshipBack', 'Selfie'],
        }),
      );
      expect(failure.kind, EmiFailureKind.rejected);
      expect(failure.missing, ['CitizenshipBack', 'Selfie']);
      expect(failure.message, 'Missing documents.');
    });

    test('status classes', () {
      expect(mapEmiFailure(http(401, null)).kind, EmiFailureKind.auth);
      expect(mapEmiFailure(http(413, '<html>')).kind, EmiFailureKind.tooLarge);
      expect(mapEmiFailure(http(502, '<html>')).kind, EmiFailureKind.server);
      expect(
        mapEmiFailure(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        ).kind,
        EmiFailureKind.offline,
      );
      expect(
        mapEmiFailure(const FormatException('bad')).kind,
        EmiFailureKind.unknown,
      );
    });
  });
}
