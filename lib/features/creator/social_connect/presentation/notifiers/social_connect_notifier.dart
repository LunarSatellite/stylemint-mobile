import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/routes/oauth_callback_scheme.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';

part 'social_connect_notifier.freezed.dart';

@freezed
abstract class SocialConnectState with _$SocialConnectState {
  const SocialConnectState._();

  const factory SocialConnectState.initial() = _SocialConnectInitial;
  const factory SocialConnectState.loadInProgress() =
      _SocialConnectLoadInProgress;
  const factory SocialConnectState.loadSuccess(
    List<SocialAccount> accounts,
  ) = _SocialConnectLoadSuccess;
  const factory SocialConnectState.loadFailure(NetworkExceptions failure) =
      _SocialConnectLoadFailure;
}

class SocialConnectNotifier extends StateNotifier<SocialConnectState> {
  SocialConnectNotifier(this._repository)
    : super(const SocialConnectState.initial()) {
    unawaited(load());
  }

  final SocialConnectRepository _repository;

  Future<void> load() async {
    state = const SocialConnectState.loadInProgress();
    final either = await _repository.getConnectedAccounts();
    state = either.fold(
      SocialConnectState.loadFailure,
      SocialConnectState.loadSuccess,
    );
  }

  /// Starts the OAuth flow: fetches the provider authorize URL and opens it.
  ///
  /// **iOS** uses ASWebAuthenticationSession ([FlutterWebAuth2]): a sheet over
  /// the app that returns the callback URL directly and dismisses itself. The
  /// alternatives both failed here — `inAppBrowserView` is
  /// SFSafariViewController, which refuses to follow a redirect to a custom
  /// URL scheme, so `stylemint://social-connected` was blocked at the final
  /// hop even though the provider had authorised and the backend had already
  /// exchanged the code; and `externalApplication` opened real Safari, which
  /// does deliver the deep link but throws the user out of the app and leaves
  /// a tab behind that nothing can close.
  ///
  /// **Android** keeps the Custom Tab: it follows custom-scheme redirects, the
  /// deep-link handler routes to [onConnectReturn], and it can be closed.
  /// Completion is NOT awaited on that path.
  Future<NetworkExceptions?> connect(SocialPlatform platform) async {
    final either = await _repository.beginConnect(platform);
    return either.fold(
      (failure) async => failure,
      (auth) async {
        final url = auth.authorizationUrl;
        if (url.isEmpty) {
          return const NetworkExceptions.unexpectedError();
        }
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return _connectIos(url);
        }
        return _connectAndroid(url);
      },
    );
  }

  Future<NetworkExceptions?> _connectIos(String url) async {
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: oauthCallbackScheme,
        options: const FlutterWebAuth2Options(preferEphemeral: false),
      );
    } on PlatformException {
      // Sheet dismissed by the user. Deliberate, so not a failure to report.
      return null;
    } catch (_) {
      return const NetworkExceptions.unexpectedError();
    }

    // The session already closed itself, so unlike the Android path there is
    // no browser to dismiss — go straight to the same completion handler.
    final callback = Uri.parse(result);
    final status = callback.queryParameters['status'];
    await onConnectReturn(
      ok: status == 'ok',
      errorCode: callback.queryParameters['error'],
    );
    return null;
  }

  Future<NetworkExceptions?> _connectAndroid(String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!launched) {
        return const NetworkExceptions.unexpectedError();
      }
      return null;
    } catch (_) {
      // No browser available / malformed URL.
      return const NetworkExceptions.unexpectedError();
    }
  }

  /// Invoked by the deep-link handler when the backend's
  /// `stylemint://social-connected` redirect arrives. Dismisses the in-app
  /// browser and refreshes the account list on success.
  Future<void> onConnectReturn({required bool ok, String? errorCode}) async {
    await closeInAppWebView();
    if (ok) {
      await refresh();
      return;
    }
    // The connect failed server-side (token exchange or profile fetch). Surface
    // the backend's reason instead of silently closing — otherwise the user
    // only discovers the failure later as a 404 when listing reels.
    final reason = errorCode?.trim().isNotEmpty ?? false
        ? errorCode!.trim()
        : 'unknown';
    debugPrint('Social connect failed: errorCode=$reason');
    state = SocialConnectState.loadFailure(
      NetworkExceptions.server('Connection failed ($reason).'),
    );
  }

  /// Reloads the accounts without switching to
  /// [SocialConnectState.loadInProgress], so screens keep the current list
  /// (no full-page spinner) and swap in the fresh one when it arrives. A failed
  /// refresh keeps the current list.
  Future<void> refresh() async {
    final either = await _repository.getConnectedAccounts();
    either.fold(
      (_) {},
      (accounts) => state = SocialConnectState.loadSuccess(accounts),
    );
  }

  /// Disconnects [platform]. On success its card disappears straight away and
  /// the list refreshes quietly; on failure nothing changes and the failure is
  /// returned so the screen can say so.
  Future<NetworkExceptions?> disconnect(SocialPlatform platform) async {
    final either = await _repository.disconnectPlatform(platform);
    return either.fold<NetworkExceptions?>(
      (failure) => failure,
      (_) {
        state.maybeWhen<void>(
          loadSuccess: (accounts) => state = SocialConnectState.loadSuccess(
            accounts
                .where((a) => a.platform != platform)
                .toList(growable: false),
          ),
          orElse: () {},
        );
        unawaited(refresh());
        return null;
      },
    );
  }
}
