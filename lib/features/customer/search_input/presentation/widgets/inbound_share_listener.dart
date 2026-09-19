import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/inbound_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/app_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Turns "shared to StyleMint" into the screenshot search screen.
///
/// Sharing is not a Discover gesture — a buyer shares a post to StyleMint
/// from wherever they happen to be, with the app cold or already open. So
/// this sits above the router rather than on a screen, and hands the bytes
/// to exactly the same route the Discover button pushes. There is one
/// screenshot path and this is how the share sheet reaches it.
///
/// It only routes. It does not decode, upload, or keep the bytes; the
/// screen's confirm step still stands between a shared picture and the
/// network.
class InboundShareListener extends ConsumerStatefulWidget {
  const InboundShareListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<InboundShareListener> createState() =>
      _InboundShareListenerState();
}

class _InboundShareListenerState extends ConsumerState<InboundShareListener> {
  StreamSubscription<InboundShare>? _subscription;

  @override
  void initState() {
    super.initState();
    final source = ref.read(inboundShareSourceProvider);
    _subscription = source.shares.listen(_open);
    unawaited(_openLaunchShare(source));
  }

  Future<void> _openLaunchShare(InboundShareSource source) async {
    final share = await source.takeLaunchShare();
    if (share != null && mounted) _open(share);
  }

  void _open(InboundShare share) {
    // The router instance rather than this context: the app builder sits
    // above the Router, so there is no GoRouter in the tree here.
    unawaited(
      ref
          .read(appRouterProvider)
          .push(RouteNames.searchScreenshot, extra: share.bytes),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
