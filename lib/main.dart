import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/format_date.dart';
import 'app.dart';
import 'features/creator/social_connect/shared/providers.dart';
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
    // Backend API URLs (e.g. the OAuth callback
    // /v1/social/connect/*/callback) are NOT app routes. They must be handled
    // server-side; if one reaches us (App Links can over-match on the shared
    // domain), ignore it rather than navigating GoRouter to a dead path.
    if (uri.path.startsWith('/v1/')) return;

    // OAuth return from a social-provider connect flow. The backend exchanges
    // the code server-side, then redirects to
    // `stylemint://social-connected?provider=...&status=ok|error`. Hand off to
    // the notifier, which closes the in-app browser and refreshes on success.
    if (uri.scheme == 'stylemint' && uri.host == 'social-connected') {
      final ok = uri.queryParameters['status'] == 'ok';
      ref.read(socialConnectNotifierProvider.notifier).onConnectReturn(ok: ok);
      return;
    }

    final router = ref.read(appRouterProvider);
    // Convert the incoming deep link to a go_router path.
    //  - https links: the host is the domain, so the route is just `uri.path`
    //    (e.g. https://host/auth/magic -> /auth/magic).
    //  - custom-scheme links: the first path segment lands in `uri.host`, so
    //    rebuild it (e.g. stylemint://auth/magic -> /auth/magic, not /magic).
    final rawPath = uri.scheme == 'stylemint' && uri.host.isNotEmpty
        ? '/${uri.host}${uri.path}'
        : uri.path;
    final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    final query = uri.queryParametersAll.isEmpty
        ? ''
        : '?${uri.queryParameters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    router.go('$path$query');
  }

  @override
  Widget build(BuildContext context) => const StyleMintApp();
}
