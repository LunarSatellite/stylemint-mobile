import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

/// Full-page load error with offline, signed-out and not-found variants.
class OrdersLoadErrorView extends StatelessWidget {
  const OrdersLoadErrorView({
    required this.failure,
    required this.onRetry,
    required this.subject,
    super.key,
  });

  final NetworkExceptions failure;
  final VoidCallback onRetry;

  /// What failed to load, e.g. "your returns".
  final String subject;

  @override
  Widget build(BuildContext context) {
    if (failure.isNoInternet) {
      return MallEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'You’re offline',
        body: 'Check your connection, then try again.',
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }
    if (failure.isAuth) {
      return MallEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to continue',
        body: 'Sign in to see $subject.',
        actionLabel: 'Sign in',
        onAction: () => context.push(RouteNames.signInMethod),
      );
    }
    if (failure.isNotFound) {
      return MallEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Not found',
        body: 'We couldn’t find $subject. It may belong to another account.',
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }
    return MallEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Couldn’t load $subject',
      body: 'Something went wrong on our side. Please try again.',
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

/// Keeps a full-page state scrollable so pull-to-refresh still works.
class OrdersScrollableState extends StatelessWidget {
  const OrdersScrollableState({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
