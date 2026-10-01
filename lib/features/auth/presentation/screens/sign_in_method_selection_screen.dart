import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/passkey_how_it_works.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/routes/oauth_callback_scheme.dart';

/// Auth entry — **passkey first**.
///
/// The default screen is intentionally just the passkey CTA (no method
/// buttons). Passkey is the highest-priority path — the device decides the
/// actual factor (Face / fingerprint / PIN). Email / phone / social and
/// "Create account" (Plan B) replace it when the user taps "More ways to
/// continue".
///
/// "Continue with Passkey" runs a real usernameless WebAuthn sign-in: the OS
/// presents whatever credential the device has, the server resolves the account
/// and issues a session (router redirects to home). If this device has no
/// passkey yet — a new user — we route to signup to create one.
class SignInMethodSelectionScreen extends ConsumerStatefulWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  ConsumerState<SignInMethodSelectionScreen> createState() =>
      _SignInMethodSelectionScreenState();
}

class _SignInMethodSelectionScreenState
    extends ConsumerState<SignInMethodSelectionScreen> {
  bool _showMore = true;
  bool _busy = false;

  /// Post-passkey routing. Collect a name first if the account has none
  /// confirmed; otherwise new accounts onboard via pick-interests, existing go
  /// home. Keyed on displayNameConfirmed (not isNewAccount) because passkey
  /// bootstrap already captures the name in its sheet.
  void _routeAfterAuth(AuthResponseDto auth) {
    if (!auth.displayNameConfirmed) {
      context.go(
        RouteNames.completeName,
        extra: {'accountId': auth.accountId},
      );
      return;
    }
    context.go(
      auth.isNewAccount ? RouteNames.pickInterests : RouteNames.home,
    );
  }

  Future<void> _continueWithPasskey() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(passkeyAuthProvider.notifier).authenticateUsernameless();
    if (!mounted) return;
    setState(() => _busy = false);

    final state = ref.read(passkeyAuthProvider);
    state.maybeWhen(
      // Success: session is persisted + rechecked. Navigate explicitly (the
      // router redirect alone doesn't reliably move us off this screen).
      loadSuccess: (auth) => _routeAfterAuth(auth),
      loadFailure: (failure) {
        // No credential on this device → this is a new user; offer the
        // passkey-first quick signup (display name only).
        if (failure.validationCode == 'PASSKEY_NO_CREDENTIALS') {
          _startBootstrapSignup();
          return;
        }
        // User cancelled the OS sheet — stay put, no error noise.
        if (failure.isAuth) return;
        // Server/gateway down (502/503/504) or offline — this isn't a passkey
        // problem, so say so plainly rather than telling the user to retry a
        // ceremony that will keep failing until the backend is back.
        if (failure.isServerUnavailable || failure.isNoInternet) {
          SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
          return;
        }
        // Everything the ceremony can distinguish, said plainly. These used to
        // fall through to "Could not sign in with passkey. Try again." — one
        // sentence for six different causes, most of which retrying cannot
        // fix. A device without passkey support, a domain that is not
        // associated and a missing Google account each need a different
        // response from the person holding the phone, and none of them is
        // "try again". It also made the failures undiagnosable from outside:
        // the OS-level error never reaches the server, so the message on
        // screen is the only evidence there is.
        final message = switch (failure.validationCode) {
          'PASSKEY_DOMAIN_NOT_ASSOCIATED' =>
            'This app is not yet associated with the StyleMint domain. '
                'Reinstalling the app usually fixes it.',
          'PASSKEY_DEVICE_NOT_SUPPORTED' =>
            'This device does not support passkeys. Use Email or Phone.',
          'PASSKEY_NO_GOOGLE_ACCOUNT' =>
            'Add a Google account on this device to use passkeys, '
                'or sign in with Email or Phone.',
          'PASSKEY_SYNC_UNAVAILABLE' =>
            'Turn on password syncing for this device to use passkeys, '
                'or sign in with Email or Phone.',
          'PASSKEY_TIMEOUT' =>
            'Passkey sign-in timed out. Your device may not support this — '
                'try Email or Phone instead.',
          'PASSKEY_OPTIONS_INVALID' =>
            'Passkey sign-in is misconfigured on our side. '
                'Please use Email or Phone for now.',
          _ => 'Could not sign in with passkey. Try again.',
        };
        SmSnackbar.error(context, message);
      },
      orElse: () {},
    );
  }

  /// Passkey-first signup: ask only for a display name, then create the account
  /// + register a passkey + issue a session in one go (email/phone come later).
  Future<void> _startBootstrapSignup() async {
    final displayName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.s16),
        ),
      ),
      builder: (_) => const _DisplayNameSheet(),
    );
    if (displayName == null || displayName.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    await ref
        .read(passkeyBootstrapProvider.notifier)
        .signup(displayName: displayName.trim());
    if (!mounted) return;
    setState(() => _busy = false);

    ref
        .read(passkeyBootstrapProvider)
        .maybeWhen(
          // Success: session is persisted + rechecked. Navigate explicitly.
          loadSuccess: (auth) => _routeAfterAuth(auth),
          loadFailure: (failure) {
            if (failure.isAuth) return;
            SmSnackbar.error(
              context,
              'Could not create your account. Please try again.',
            );
          },
          orElse: () {},
        );
  }

  /// Social sign-in (Apple / Google / Facebook). Fetches the authorization URL
  /// and stashes the CSRF state, then opens the provider.
  ///
  /// Two paths, because the platforms differ in what can catch the final
  /// redirect to `stylemint://auth/oauth/callback?code=&state=`:
  ///
  /// - **iOS** uses ASWebAuthenticationSession via [FlutterWebAuth2]. It is a
  ///   sheet over this screen, not a trip to Safari, it *returns* the callback
  ///   URL to the caller, and it closes itself on the way back. We then push
  ///   the callback route ourselves.
  /// - **Android** keeps the Custom Tab + deep link it has always used, which
  ///   already slides over the app and already follows custom schemes.
  Future<void> _startSocial(String provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    final url = await ref
        .read(oauthSignInProvider.notifier)
        .authorize(provider);
    if (!mounted) return;
    setState(() => _busy = false);

    if (url == null || url.isEmpty) {
      SmSnackbar.error(
        context,
        'Could not start $provider sign-in. Please try again.',
      );
      return;
    }

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await _startSocialIos(provider, url);
      return;
    }
    await _startSocialAndroid(provider, url);
  }

  /// iOS: ASWebAuthenticationSession.
  ///
  /// This replaces `launchUrl(externalApplication)`, which was itself a
  /// workaround. `inAppBrowserView` on iOS is SFSafariViewController, which
  /// refuses to follow a redirect to a custom URL scheme — a documented
  /// restriction — so the callback was blocked at the last hop: the provider
  /// authenticated the person, the server minted a session, and the app never
  /// heard about it. Sign in with Apple showed it most clearly, because Face
  /// ID visibly succeeded first.
  ///
  /// Opening real Safari instead did deliver the deep link, at the cost of
  /// throwing the user out of the app and leaving a tab behind that
  /// `closeInAppWebView()` could not dismiss (it can only close what
  /// url_launcher opened). ASWebAuthenticationSession is the API built for
  /// exactly this: it owns the callback scheme for the duration of the
  /// session, hands the URL straight back, and dismisses itself.
  Future<void> _startSocialIos(String provider, String url) async {
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: url,
        // Scheme only — the session matches on it and returns the whole URL.
        callbackUrlScheme: oauthCallbackScheme,
        options: const FlutterWebAuth2Options(
          // Not ephemeral: a person who is already signed in to Google in
          // Safari should not have to type their password again, and Apple's
          // own sheet relies on the existing session too.
          preferEphemeral: false,
        ),
      );
    } on PlatformException {
      // The user dismissed the sheet. Not an error worth a red snackbar —
      // they cancelled on purpose and are looking at this screen already.
      return;
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(
          context,
          'Could not open the $provider sign-in page.',
        );
      }
      return;
    }

    if (!mounted) return;

    // Hand off to the same screen the Android deep link lands on, so the CSRF
    // check, the code exchange and the new-vs-returning routing all stay in
    // one place.
    final callback = Uri.parse(result);
    context.go(
      Uri(
        path: RouteNames.oauthCallback,
        queryParameters: {
          'code': callback.queryParameters['code'] ?? '',
          'state': callback.queryParameters['state'] ?? '',
          if (callback.queryParameters['error'] != null)
            'error': callback.queryParameters['error']!,
        },
      ).toString(),
    );
  }

  /// Android: Chrome Custom Tab, which does follow custom-scheme redirects and
  /// can be closed afterwards. The provider sends the browser to
  /// `stylemint://auth/oauth/callback?...`; the app's deep-link handler routes
  /// to [OAuthCallbackScreen], which dismisses the tab and finishes.
  ///
  /// url_launcher rather than FlutterWebBrowser: `closeInAppWebView()` can
  /// only close a browser url_launcher itself opened. Opened the other way it
  /// stayed on top of the app forever, still showing the provider's page,
  /// which is indistinguishable from sign-in not working.
  Future<void> _startSocialAndroid(String provider, String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched && mounted) {
        SmSnackbar.error(
          context,
          'Could not open the $provider sign-in page.',
        );
      }
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(
          context,
          'Could not open the $provider sign-in page.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s4,
                  DesignTokens.s16,
                  DesignTokens.s24,
                ),
                child: Column(
                  children: [
                    // Default view = the "Login - Passkey" spec page, verbatim:
                    // icon → title → subtitle → How it works → Setup button.
                    if (!_showMore) ...[
                      const SizedBox(height: DesignTokens.s8),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          'assets/images/auth/auth_passkey_fingerprint.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      Text(
                        'Continue with Passkey',
                        textAlign: TextAlign.center,
                        style: DesignTokens.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        'Sign in with just your finger print. Password-less, '
                        'secure and works across all devices',
                        textAlign: TextAlign.center,
                        style: DesignTokens.bodyText,
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      const PasskeyHowItWorks(),
                      const SizedBox(height: DesignTokens.s24),
                      SizedBox(
                        width: double.infinity,
                        child: SmPrimaryButton(
                          label: 'Continue with Passkey',
                          height: DesignTokens.buttonHeight,
                          borderRadius: DesignTokens.buttonRadius,
                          color: DesignTokens.primaryGreen,
                          labelColor: DesignTokens.buttonPrimaryText,
                          disabled: _busy,
                          isLoadingInitially: _busy,
                          onPressed: _continueWithPasskey,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                      // Creating a passkey used to be reachable only by
                      // failing to sign in with one: the bootstrap signup ran
                      // from the PASSKEY_NO_CREDENTIALS branch of
                      // _continueWithPasskey and nowhere else. When the
                      // ceremony reported anything but that exact code — which
                      // on a device with no credentials it often does — a new
                      // user had no route to a passkey at all. The database
                      // showed it plainly: 23 authentication challenges issued,
                      // zero credentials ever registered.
                      //
                      // A first-time user should not have to trigger a failure
                      // to find the way in, so signup is its own button. The
                      // fallback stays for anyone who taps the top CTA first.
                      TextButton(
                        onPressed: _busy ? null : _startBootstrapSignup,
                        child: Text(
                          "New here? Create an account",
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showMore = true),
                        child: Text(
                          'More ways to continue',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: DesignTokens.s24),
                      Text(
                        'Welcome to StyleMint',
                        textAlign: TextAlign.center,
                        style: DesignTokens.titleMedium,
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        'Choose how you want to continue',
                        textAlign: TextAlign.center,
                        style: DesignTokens.bodyText,
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      _PlanB(
                        // Same usernameless sign-in as the top button (with
                        // bootstrap-signup fallback) — NOT the login-required
                        // /passkey Setup screen.
                        onPasskey: _continueWithPasskey,
                        onSocial: _startSocial,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

/// Plan B — all sign-in options including passkey as a row.
class _PlanB extends ConsumerWidget {
  const _PlanB({
    required this.onPasskey,
    required this.onSocial,
  });

  /// Triggers usernameless passkey authentication. Null while busy.
  final VoidCallback? onPasskey;

  /// Starts the OAuth browser flow for the provider named.
  final Future<void> Function(String provider) onSocial;

  /// Icon and label per provider name, keyed by the enum name the server
  /// returns and the same value posted back to `/authorize`. A provider the
  /// server offers but this map does not know is skipped rather than drawn
  /// unlabelled — a blank button is worse than an absent one.
  static const _brands = <String, ({String asset, String label})>{
    'Google': (asset: 'assets/icons/google.svg', label: 'Google ID'),
    'Apple': (asset: 'assets/icons/apple.svg', label: 'Apple ID'),
    'Facebook': (asset: 'assets/icons/facebook.svg', label: 'Facebook ID'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.s8),
        _MethodRow(
          icon: Icons.key_rounded,
          iconTileColor: const Color(0xFFFFC107),
          iconColor: Colors.black,
          title: 'Use Passkey (Recommended)',
          description: 'Fast, secure & no password needed',
          onTap: onPasskey ?? () {},
        ),
        _MethodRow(
          icon: Icons.mail_rounded,
          iconTileColor: DesignTokens.bgAppBodyLight,
          iconColor: DesignTokens.textLight,
          title: 'Continue with Email',
          description: 'Use your email to sign-in',
          onTap: () => context.push(RouteNames.email),
        ),
        _MethodRow(
          icon: Icons.phone_iphone,
          iconTileColor: DesignTokens.bgAppBodyLight,
          iconColor: DesignTokens.textLight,
          title: 'Continue with Phone No.',
          description: 'Use your phone No. to sign-in',
          onTap: () => context.push(RouteNames.login),
        ),
        const SizedBox(height: DesignTokens.s16),

        //
        // // Create account — smart-start: a new email/phone provisions an
        // // account automatically on OTP verify, so "create" and "sign in" are
        // // the same flow. Route to the email entry (no separate signup screen).
        // Center(
        //   child: GestureDetector(
        //     onTap: () => context.push(RouteNames.email),
        //     child: Text.rich(
        //       TextSpan(
        //         children: [
        //           TextSpan(
        //             text: 'New to Style Mint? ',
        //             style: DesignTokens.smallRegular
        //                 .copyWith(color: DesignTokens.textLight),
        //           ),
        //           TextSpan(
        //             text: 'Create account',
        //             style: DesignTokens.smallRegular.copyWith(
        //               color: DesignTokens.primaryGreen,
        //               fontWeight: FontWeight.w600,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(height: DesignTokens.s24),
        Row(
          children: [
            const Expanded(
              child: Divider(color: DesignTokens.borderDefault, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              child: Text(
                'Or Continue With',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: DesignTokens.borderDefault, height: 1),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s24),

        // Driven by the server rather than hardcoded, so a provider appears
        // when its credentials are configured and stops being offered when
        // they are pulled — neither needing a new build. While the lookup is
        // in flight, or if it failed, nothing is drawn: the email, phone and
        // passkey paths above are unaffected, and an empty gap is honest
        // where a button that cannot complete a sign-in is not.
        ...ref
            .watch(oauthProvidersProvider)
            .maybeWhen(
              data: (providers) => providers
                  .map((name) => (name: name, brand: _brands[name]))
                  .where((p) => p.brand != null)
                  .expand(
                    (p) => [
                      _SocialButton(
                        assetPath: p.brand!.asset,
                        label: p.brand!.label,
                        onTap: () => onSocial(p.name),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                    ],
                  )
                  .toList(),
              orElse: () => const <Widget>[],
            ),
      ],
    );
  }
}

/// Full-width gray pill social button: [logo] [label].
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: Material(
        color: DesignTokens.buttonGrayFill,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(assetPath, width: 20, height: 20),
              const SizedBox(width: DesignTokens.s8),
              Text(label, style: DesignTokens.oneLinerSemibold),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal top app bar with a back chevron.
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: DesignTokens.textWhite,
          size: DesignTokens.iconMedium,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.popOrHome();
          } else {
            context.go(RouteNames.userTypeSelection);
          }
        },
      ),
    );
  }
}

/// A tappable sign-in method row: [icon tile] [title + description] [chevron].
class _MethodRow extends StatelessWidget {
  final IconData icon;
  final Color iconTileColor;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MethodRow({
    required this.icon,
    required this.iconTileColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconTileColor,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: DesignTokens.iconMedium,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: DesignTokens.smallDescription),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.textLight,
              size: DesignTokens.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that collects just a display name for passkey-first signup.
/// Pops with the entered name (or null on cancel).
class _DisplayNameSheet extends StatefulWidget {
  const _DisplayNameSheet();

  @override
  State<_DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends State<_DisplayNameSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s24,
        DesignTokens.s16,
        DesignTokens.s24 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: DesignTokens.titleMedium),
          const SizedBox(height: DesignTokens.s8),
          Text(
            "Pick a display name to get started. You'll add your email and phone "
            'later — your device passkey is all you need to sign in.',
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s24),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 64,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            cursorColor: DesignTokens.primaryGreen,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: InputDecoration(
              hintText: 'Sarah',
              filled: true,
              fillColor: DesignTokens.inputFieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide: const BorderSide(
                  color: DesignTokens.inputFieldBorder,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          SizedBox(
            width: double.infinity,
            child: SmPrimaryButton(
              label: 'Continue with Passkey',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              onPressed: () async => _submit(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer with Terms & Conditions / Privacy Policy links.
///
/// These were styled green to read as links but carried no recognizer, so
/// nothing happened when they were tapped — the documents were reachable only
/// from Settings, after signing in, which is exactly backwards for text that
/// says "by continuing you agree". Both routes are public, so they open
/// signed out.
class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  // Recognizers hold gesture state, so they are owned by the State and
  // disposed with it rather than rebuilt on every frame.
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => unawaited(context.push(RouteNames.legalTerms));
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => unawaited(context.push(RouteNames.legalPrivacy));

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regular = DesignTokens.mediumRegular.copyWith(
      color: DesignTokens.textWhite,
    );
    final link = DesignTokens.mediumSemibold.copyWith(
      color: DesignTokens.primaryGreen,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'By Continuing you acknowledge that you read & agree our ',
              style: regular,
            ),
            TextSpan(
              text: 'Terms & Conditions',
              style: link,
              recognizer: _terms,
              semanticsLabel: 'Terms and Conditions, opens the document',
            ),
            TextSpan(text: ' and ', style: regular),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: _privacy,
              semanticsLabel: 'Privacy Policy, opens the document',
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
