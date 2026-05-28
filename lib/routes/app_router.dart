import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sign_in_method_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/email_login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/passkey_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/otp_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/onboarding_carousel_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/pick_interests_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/follow_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reels_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (ctx, state) => const OnboardingCarouselScreen(),
      ),
      GoRoute(
        path: RouteNames.signInMethod,
        builder: (ctx, state) => const SignInMethodSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.email,
        builder: (ctx, state) => const EmailLoginScreen(),
      ),
      // Default passkey entry — picks Face variant (TODO: detect device biometric)
      GoRoute(
        path: RouteNames.passkey,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.face),
      ),
      GoRoute(
        path: RouteNames.passkeyFace,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.face),
      ),
      GoRoute(
        path: RouteNames.passkeyFingerprint,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.fingerprint),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phone: extra['phone'] as String,
            otpId: extra['otpId'] as String,
            identifierType: (extra['identifierType'] as String?) ?? 'phone',
          );
        },
      ),
      GoRoute(
        path: RouteNames.userTypeSelection,
        builder: (ctx, state) {
          return UserTypeSelectionScreen(
            authData: state.extra as AuthResponseDto,
          );
        },
      ),
      GoRoute(
        path: RouteNames.pickInterests,
        builder: (ctx, state) => const PickInterestsScreen(),
      ),
      GoRoute(
        path: RouteNames.followCreators,
        builder: (ctx, state) => const FollowCreatorsScreen(),
      ),
      // Deprecated route — kept for backwards compatibility
      GoRoute(
        path: RouteNames.rolePicker,
        builder: (ctx, state) {
          return UserTypeSelectionScreen(
            authData: state.extra as AuthResponseDto,
          );
        },
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (ctx, state) => const _Placeholder('Home'),
      ),
      GoRoute(
        path: RouteNames.reelsFeed,
        builder: (ctx, state) => const ReelsFeedScreen(),
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
