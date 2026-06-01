import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/format_date.dart';
import 'app.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezone();

  runApp(
    const ProviderScope(
      child: _AppWithDeepLinks(),
    ),
  );
}

/// Wraps [StyleMintApp] and listens for incoming deep links so that magic-link
/// and OAuth callback URIs are routed to the correct screen.
///
/// Deep-link format:
///   `stylemint://auth/magic?token=<token>`
///   `https://stylemint.voyageritnepal.com/auth/magic?token=<token>`
class _AppWithDeepLinks extends ConsumerStatefulWidget {
  const _AppWithDeepLinks();

  @override
  ConsumerState<_AppWithDeepLinks> createState() => _AppWithDeepLinksState();
}

class _AppWithDeepLinksState extends ConsumerState<_AppWithDeepLinks> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _listenDeepLinks();
  }

  void _listenDeepLinks() {
    _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {}, // silently ignore malformed links
    );
    // Also handle the initial link that launched the app cold.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    }).catchError((_) {});
  }

  void _handleUri(Uri uri) {
    final router = ref.read(appRouterProvider);
    // Convert the incoming deep link to a go_router path.
    // Supports both custom-scheme and https-scheme links.
    final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final query = uri.queryParametersAll.isEmpty
        ? ''
        : '?${uri.queryParameters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    router.go('$path$query');
  }

  @override
  Widget build(BuildContext context) => const StyleMintApp();
}
