import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
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

  /// Starts the OAuth flow: fetches the provider authorize URL and opens it in
  /// an in-app browser tab (Custom Tab / SFSafariViewController). Completion is
  /// NOT awaited here — the backend exchanges the code server-side and then
  /// redirects to `stylemint://social-connected?status=ok|error`, which the
  /// app's deep-link handler routes to [onConnectReturn].
  Future<NetworkExceptions?> connect(SocialPlatform platform) async {
    final either = await _repository.beginConnect(platform);
    return either.fold(
      (failure) async => failure,
      (auth) async {
        final url = auth.authorizationUrl;
        if (url.isEmpty) {
          return const NetworkExceptions.unexpectedError();
        }
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
      },
    );
  }

  /// Invoked by the deep-link handler when the backend's
  /// `stylemint://social-connected` redirect arrives. Dismisses the in-app
  /// browser and refreshes the account list on success.
  Future<void> onConnectReturn({required bool ok, String? errorCode}) async {
    await closeInAppWebView();
    if (ok) {
      await load();
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

  Future<void> disconnect(SocialPlatform platform) async {
    final either = await _repository.disconnectPlatform(platform);
    either.fold(
      (_) => null,
      (_) => unawaited(load()),
    );
  }
}
