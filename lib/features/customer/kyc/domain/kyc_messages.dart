import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';

/// The contract's KYC error codes.
abstract final class KycErrorCode {
  static const alreadyApproved = 'kyc.already_approved';
  static const documentsMissing = 'kyc.documents_missing';
  static const underage = 'kyc.underage';
  static const addressNotFound = 'kyc.address_not_found';
  static const documentNumberInUse = 'kyc.document_number_in_use';
}

/// Problems the app finds itself, before anything is sent. Prefixed so they
/// can never be mistaken for a server code.
abstract final class KycLocalCode {
  static const photoGone = 'app.kyc.photo_gone';
  static const photoEmpty = 'app.kyc.photo_empty';
  static const photoTooLarge = 'app.kyc.photo_too_large';
  static const detailsIncomplete = 'app.kyc.details_incomplete';
}

/// "Front of your citizenship and Selfie" for the wire kinds in [missing].
String describeKycKinds(Iterable<String> missing) {
  final labels = [
    for (final wire in missing) KycDocumentKind.fromWire(wire)?.label ?? wire,
  ];
  if (labels.isEmpty) return 'every photo';
  if (labels.length == 1) return labels.single;
  return '${labels.sublist(0, labels.length - 1).join(', ')} and '
      '${labels.last}';
}

String _page(EmiFailure failure) =>
    describeKycKinds(failure.missing).toLowerCase();

/// The sentence the KYC flow shows for [failure]. Every contract code has its
/// own; anything else falls back to the shared wording, then to the server's
/// sentence.
String kycErrorMessage(EmiFailure failure) {
  switch (failure.code) {
    case KycErrorCode.alreadyApproved:
      return 'You are already verified — there is nothing more to send.';
    case KycErrorCode.documentsMissing:
      return failure.missing.isEmpty
          ? 'Some photos are missing. Add every photo the form asks for.'
          : 'Add ${describeKycKinds(failure.missing)} before you submit.';
    case KycErrorCode.underage:
      return 'You must be 18 or older to verify for EMI. Check your date of '
          'birth.';
    case KycErrorCode.addressNotFound:
      return 'That address is no longer saved. Pick another one or add a new '
          'address.';
    case KycErrorCode.documentNumberInUse:
      return 'This document is already verified on another StyleMint account. '
          'Each person can verify one account only — contact support if you '
          'think this is a mistake.';
    case KycLocalCode.photoGone:
      return 'The photo of the ${_page(failure)} is no longer on this device. '
          'Take or pick it again.';
    case KycLocalCode.photoEmpty:
      return 'The photo of the ${_page(failure)} came through empty. Take it '
          'again.';
    case KycLocalCode.photoTooLarge:
      return 'The photo of the ${_page(failure)} is larger than 10 MB. Take '
          'it again.';
    case KycLocalCode.detailsIncomplete:
      return 'Fill in every detail and pick an address before you submit.';
  }
  return switch (failure.kind) {
    EmiFailureKind.notFound =>
      'Identity verification for EMI is not open yet. Please try again later.',
    EmiFailureKind.tooLarge =>
      'Those photos are too large. Take them again — each must be under 10 MB.',
    EmiFailureKind.offline =>
      'You appear to be offline. Try again once you have a connection — '
          'nothing more has been sent.',
    _ =>
      emiCommonMessage(failure) ??
          serverMessageOr(
            failure,
            'We could not send your verification. Please try again.',
          ),
  };
}
