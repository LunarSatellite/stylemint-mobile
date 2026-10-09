import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/emi_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `VendorEmiTermsDto`. A never-configured product comes back with
/// `enabled: false` and defaults, which read the same way here.
VendorEmiTerms readVendorEmiTerms(Map<String, dynamic> json) {
  final minDown = readInt(json['minDownPaymentPercent']);
  final effective = readInt(json['effectiveMinDownPaymentPercent']);
  final chosen = minDown <= 0 ? emiMinDownPaymentPercent : minDown;
  final sample = json['sampleQuote'];
  return VendorEmiTerms(
    productId: readString(json['productId']),
    productName: readString(json['productName']),
    enabled: readBool(json['enabled']),
    minDownPaymentPercent: chosen,
    effectiveMinDownPaymentPercent: effective <= 0 ? chosen : effective,
    tenures: readTenures(json['tenures']),
    interestRatePercentMonthly:
        readOptionalDouble(json['interestRatePercentMonthly']) ?? 0,
    approvalMode: readOptionalString(json['approvalMode']) ?? 'Manual',
    eligibleVariantCount: readInt(json['eligibleVariantCount']),
    minimumPrice: readMoney(json['minimumPrice']),
    sampleQuote: sample is Map<String, dynamic> ? readEmiQuote(sample) : null,
    updatedUtc: readDate(json['updatedUtc']),
  );
}

/// The PUT body. Interest and approval mode are fixed in phase 1 (0 and
/// `Manual`); they are sent so the server, not the app, rejects anything else.
Map<String, dynamic> vendorEmiTermsBody({
  required bool enabled,
  required int minDownPaymentPercent,
  required List<int> tenures,
}) => <String, dynamic>{
  'enabled': enabled,
  'minDownPaymentPercent': minDownPaymentPercent,
  'tenures': [...tenures]..sort(),
  'interestRatePercentMonthly': 0,
  'approvalMode': 'Manual',
};

/// `{ "exposureLimit": Money|null, "maxExposureLimit": Money }`.
VendorEmiSettings readVendorEmiSettings(Map<String, dynamic> json) =>
    VendorEmiSettings(
      exposureLimit: readMoney(json['exposureLimit']),
      maxExposureLimit:
          readMoney(json['maxExposureLimit']) ??
          const Money(amount: 500000, currency: 'NPR'),
    );

Map<String, dynamic> vendorEmiSettingsBody(Money? exposureLimit) =>
    <String, dynamic>{
      'exposureLimit': exposureLimit == null
          ? null
          : <String, dynamic>{
              'amount': exposureLimit.amount,
              'currency': exposureLimit.currency,
            },
    };
