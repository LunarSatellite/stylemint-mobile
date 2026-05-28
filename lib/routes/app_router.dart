import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (ctx, state) => const _Placeholder('Login'),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (ctx, state) => const _Placeholder('Home'),
      ),
      // TODO: wire remaining routes as screens are built per feature
    ],
    redirect: (ctx, state) {
      // TODO: auth guard — check authProvider state + role
      return null;
    },
  );
}

// Temporary placeholder — replace with the real screen as each feature is built.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(child: Text('$name — coming soon')),
    );
  }
}
