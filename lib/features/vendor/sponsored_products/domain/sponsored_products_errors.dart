import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// Validation code the repository gives a 409 from the sponsored endpoints,
/// so it can be told apart from a 400.
const sponsorshipConflictCode = 'sponsored_listing.conflict';

/// Shown for a 409 whose body has no message.
const sponsorshipConflictFallbackMessage =
    'This product is already being sponsored.';

/// True when a sponsor request lost a race with another one for the same
/// product (HTTP 409).
bool isSponsorshipConflict(NetworkExceptions failure) =>
    failure.validationCode == sponsorshipConflictCode;

/// Shown for a 404. The backend's own title carries the product id, so it is
/// never shown.
const sponsoredProductNotFoundMessage =
    "We couldn't find that product in your store.";

/// A plain sentence for a failed sponsored-products call. Backend validation
/// and business-rule messages (e.g. "Only live products can be sponsored.")
/// are shown as the backend wrote them.
String sponsoredProductsErrorMessage(NetworkExceptions failure) =>
    failure.maybeWhen(
      validation: (code, message, field, errors) {
        final lines = errors
            .map((e) => e.message.trim())
            .where((m) => m.isNotEmpty)
            .toList(growable: false);
        if (lines.isNotEmpty) return lines.join('\n');
        final text = (message ?? '').trim();
        return text.isNotEmpty ? text : _genericMessage;
      },
      notFound: () => sponsoredProductNotFoundMessage,
      noInternetConnection: () =>
          'No internet connection. Check your connection and try again.',
      serverUnavailable: () => NetworkExceptions.getMessage(failure),
      auth: () => 'Your session has ended. Sign in again to continue.',
      orElse: () => _genericMessage,
    );

const _genericMessage = 'Something went wrong. Please try again.';

/// A failed Save, split by where the sponsor form shows it: under the
/// "Most views a day" field, under the end date, or above the Save button.
@immutable
class SponsorFormErrors {
  const SponsorFormErrors({
    this.dailyImpressionCap,
    this.endsUtc,
    this.general,
  });

  /// Routes the backend's `dailyImpressionCap` / `endsUtc` errors to their
  /// fields. FluentValidation names them PascalCase (`DailyImpressionCap`)
  /// in `errors[]`; domain rules put camelCase in the top-level `field`.
  factory SponsorFormErrors.from(NetworkExceptions failure) =>
      failure.maybeWhen(
        validation: (code, message, field, errors) {
          String? cap;
          String? ends;
          final other = <String>[];

          void place(String? rawField, String text) {
            if (text.isEmpty) return;
            switch (_fieldKey(rawField)) {
              case 'dailyimpressioncap':
                cap = cap == null ? text : '$cap\n$text';
              case 'endsutc':
                ends = ends == null ? text : '$ends\n$text';
              default:
                other.add(text);
            }
          }

          if (errors.isNotEmpty) {
            for (final e in errors) {
              place(e.field, e.message.trim());
            }
          } else {
            place(field, (message ?? '').trim());
          }

          final hasFieldError = cap != null || ends != null;
          return SponsorFormErrors(
            dailyImpressionCap: cap,
            endsUtc: ends,
            general: other.isNotEmpty
                ? other.join('\n')
                : (hasFieldError
                      ? null
                      : sponsoredProductsErrorMessage(failure)),
          );
        },
        orElse: () =>
            SponsorFormErrors(general: sponsoredProductsErrorMessage(failure)),
      );

  final String? dailyImpressionCap;
  final String? endsUtc;
  final String? general;

  bool get isEmpty =>
      dailyImpressionCap == null && endsUtc == null && general == null;

  SponsorFormErrors withoutDailyImpressionCap() =>
      SponsorFormErrors(endsUtc: endsUtc, general: general);

  SponsorFormErrors withoutEndsUtc() => SponsorFormErrors(
    dailyImpressionCap: dailyImpressionCap,
    general: general,
  );

  static String _fieldKey(String? raw) =>
      (raw ?? '').toLowerCase().replaceAll(RegExp('[^a-z]'), '');
}
