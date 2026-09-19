import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/screenshot_search_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';

/// Runs one screenshot through the catalogue's visual search.
///
/// ## What leaves the device
///
/// One field, once: the normalised PNG from [ScreenshotImage.toDataUri],
/// POSTed to `/api/v1/customer/search/multimodal` together with the words
/// already typed in the search field, if any. No filename, no album, no
/// EXIF, no capture time, no second image. The request is not retried, so a
/// screenshot is transmitted exactly one time per deliberate tap.
///
/// ## What is kept
///
/// Nothing. The bytes live in the [ScreenshotImage] the caller holds and are
/// released with it. This class writes no file, touches no
/// `SharedPreferences` key, adds nothing to search history and holds no
/// mutable field of its own between calls — deliberately, so "not kept past
/// the search" is a property of the code rather than a promise in a policy.
class ScreenshotSearch {
  const ScreenshotSearch({required this.searchDataSource});

  final CustomerSearchRemoteDataSource searchDataSource;

  Future<ScreenshotSearchOutcome> run(
    ScreenshotImage screenshot, {
    String? query,
  }) async {
    final CustomerSearchResults results;
    try {
      results = await searchDataSource.searchMultimodal(
        [screenshot.toDataUri()],
        query: query,
      );
    } on NetworkExceptions catch (error) {
      return _unavailableFor(error);
    } on Object catch (_) {
      return const ScreenshotSearchUnavailable(
        'Visual search is unavailable right now. Please try again in a '
        'moment.',
      );
    }

    // The one rule this method exists to enforce: no recognition means no
    // match, and no match is said out loud. It is never turned into a
    // results screen filled with something else.
    //
    // The server now says which kind of empty it is, and that answer wins
    // over counting products — a non-empty list no longer implies the image
    // was recognised, since on the multimodal endpoint those rows can come
    // from the typed words alone. This entry point promises "found in your
    // screenshot", so anything short of a match is a dead end here.
    switch (results.imageRecognition) {
      case ImageRecognitionOutcome.recognizedNoMatch:
        return ScreenshotNoMatch(
          recognizedFeatures: results.recognizedFeatures,
        );
      case ImageRecognitionOutcome.notRecognized:
        return const ScreenshotNotRecognized();
      case ImageRecognitionOutcome.matched:
        // The server's own invariant forbids an empty match, but a client
        // that trusts that blindly renders an empty results screen if it is
        // ever broken. Cheaper to check than to ship that.
        if (results.products.isEmpty) return const ScreenshotNoMatch();
        return ScreenshotMatches(results);
      // An outcome added to the server enum after this build shipped, or no
      // outcome reported at all. Fall back to the older, safe rule rather
      // than guessing: products present are real catalogue rows, and their
      // absence is still a no-match. Nothing is invented either way.
      case ImageRecognitionOutcome.unknown:
      case null:
        if (results.products.isEmpty) return const ScreenshotNoMatch();
        return ScreenshotMatches(results);
    }
  }

  static ScreenshotSearchUnavailable _unavailableFor(
    NetworkExceptions error,
  ) => error.when(
    server: (message) => const ScreenshotSearchUnavailable(
      'Visual search is unavailable right now. Please try again in a moment.',
    ),
    serverUnavailable: () => const ScreenshotSearchUnavailable(
      'Visual search is not answering. Please try again in a moment.',
    ),
    noInternetConnection: () => const ScreenshotSearchUnavailable(
      'A screenshot search needs a connection. Reconnect and try again.',
    ),
    unexpectedError: () => const ScreenshotSearchUnavailable(
      'Visual search is unavailable right now. Please try again in a moment.',
    ),
    formatException: () => const ScreenshotSearchUnavailable(
      'StyleMint could not read visual search’s answer.',
    ),
    emptyData: () => const ScreenshotSearchUnavailable(
      'Visual search is unavailable right now. Please try again in a moment.',
    ),
    // A 4xx here is about the picture, not the buyer: too large, or an
    // image the provider refused to analyse.
    validation: (code, message, field, errors) => ScreenshotSearchUnavailable(
      'StyleMint could not search with that screenshot. Try a different one.',
      detail: code.isEmpty ? null : code,
    ),
    auth: () => const ScreenshotSearchUnavailable(
      'Sign in to search the Mall with a screenshot.',
    ),
    notFound: () => const ScreenshotSearchUnavailable(
      'Visual search is not switched on for the Mall yet. Typing still works.',
    ),
    conflict: () => const ScreenshotSearchUnavailable(
      'Visual search is unavailable right now. Please try again in a moment.',
    ),
  );
}

/// Asks the server whether it can look at images at all.
///
/// Visual search binds only when a vision provider is configured, so a
/// deployment without one answers `available: false`. That is
/// [SearchInputStatus.unsupported] and the entry point disappears — a
/// screenshot button that always fails on tap is worse than no button.
///
/// A probe that cannot complete is *not* an answer. Offline, or a 500,
/// leaves the status [SearchInputStatus.unprobed] so the button stays and
/// the next attempt can still succeed.
typedef VisualSearchProbe = Future<SearchInputStatus> Function();

Future<SearchInputStatus> probeVisualSearch(ApiClient apiClient) async {
  try {
    final response = await apiClient.get(
      '/api/v1/customer/search/image/capability',
    );
    if (response is! Map<String, dynamic>) return SearchInputStatus.unprobed;
    return response['available'] == true
        ? SearchInputStatus.ready
        : SearchInputStatus.unsupported;
  } on Object catch (_) {
    return SearchInputStatus.unprobed;
  }
}
