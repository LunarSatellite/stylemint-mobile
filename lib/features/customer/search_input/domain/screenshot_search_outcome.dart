import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

/// What a screenshot search came back with.
///
/// There are exactly three endings and none of them is "here are some
/// products you might like anyway". A screenshot the server cannot place is
/// a [ScreenshotNoMatch]; a server that cannot look at all is a
/// [ScreenshotSearchUnavailable]. Neither is allowed to borrow the results
/// shape and pass filler off as recognition.
@immutable
sealed class ScreenshotSearchOutcome {
  const ScreenshotSearchOutcome();
}

/// The server recognised something and the catalogue carries it.
///
/// [ScreenshotMatches] is only ever constructed with a non-empty product
/// list — the assertion is the guard, because an empty "match" rendered
/// through the results screen is precisely the fabrication this feature
/// must not ship.
@immutable
final class ScreenshotMatches extends ScreenshotSearchOutcome {
  ScreenshotMatches(this.results)
    : assert(
        results.products.isNotEmpty,
        'ScreenshotMatches is for real recognition only. Zero products is a '
        'ScreenshotNoMatch — never an empty results screen.',
      );

  final CustomerSearchResults results;
}

/// The image was read and understood as far as the server could, and nothing
/// in the Mall corresponds to it.
@immutable
final class ScreenshotNoMatch extends ScreenshotSearchOutcome {
  const ScreenshotNoMatch();
}

/// Visual search could not run: the provider is unconfigured, the network
/// failed, or the image was refused. [message] is shown to the buyer, so it
/// is written for them rather than copied from an exception.
@immutable
final class ScreenshotSearchUnavailable extends ScreenshotSearchOutcome {
  const ScreenshotSearchUnavailable(this.message, {this.detail});

  final String message;

  /// A short technical hint, shown small and muted under the message.
  final String? detail;
}
