import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

/// What a screenshot search came back with.
///
/// There are exactly four endings and none of them is "here are some
/// products you might like anyway". The server now separates the two ways a
/// search can come back empty, and so does this: a picture the Mall read and
/// does not stock is a [ScreenshotNoMatch], a picture that gave vision
/// nothing to search with is a [ScreenshotNotRecognized], and a server that
/// cannot look at all is a [ScreenshotSearchUnavailable]. None of them is
/// allowed to borrow the results shape and pass filler off as recognition.
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

/// Vision read the picture and the Mall does not stock what it saw.
///
/// This is the informative empty result, and the reason it is worth keeping
/// apart from [ScreenshotNotRecognized]: the platform can say *what* it saw.
/// [recognizedFeatures] carries those words — "navy", "oxford shirt",
/// "button-down collar" — so the dead end reads as "we looked for these and
/// the Mall has none" rather than as a blank shrug.
///
/// It may be empty: the multimodal endpoint reports the outcome but not the
/// features, so callers must render the generic wording when it is.
@immutable
final class ScreenshotNoMatch extends ScreenshotSearchOutcome {
  const ScreenshotNoMatch({this.recognizedFeatures = const []});

  /// What vision read out of the image. Possibly empty; never fabricated.
  final List<String> recognizedFeatures;
}

/// Vision ran and could not read anything searchable out of the picture.
///
/// Distinct from [ScreenshotNoMatch] because the customer's next move is
/// different. Nothing is known to be missing from the Mall here — the image
/// simply did not yield a feature to search on, so the useful advice is
/// about the picture, not about the catalogue.
@immutable
final class ScreenshotNotRecognized extends ScreenshotSearchOutcome {
  const ScreenshotNotRecognized();
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
