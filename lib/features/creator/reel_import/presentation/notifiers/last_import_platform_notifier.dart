import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// SharedPreferences key holding the enum `name` of the [SocialPlatform] the
/// creator last imported from.
const lastImportPlatformKey = 'creator_reel_import_last_platform';

/// Platform the Import Reel screen opens on: the saved one, else the first
/// connected account, else Instagram.
SocialPlatform resolveImportPlatform({
  SocialPlatform? saved,
  Iterable<SocialAccount> accounts = const [],
}) {
  if (saved != null) return saved;
  for (final account in accounts) {
    if (account.isConnected) return account.platform;
  }
  return SocialPlatform.instagram;
}

/// Device-local memory of the last platform used on the Import Reel screen.
/// Like the appearance preference, it is not account data and is not sent to
/// the API. State is null until restored or when nothing was saved.
class LastImportPlatformNotifier extends StateNotifier<SocialPlatform?> {
  LastImportPlatformNotifier() : super(null) {
    restored = _restore();
  }

  /// Completes with the saved platform (or null) once preferences are read.
  /// Screens await this before choosing what to load.
  late final Future<SocialPlatform?> restored;

  bool _chosen = false;

  Future<SocialPlatform?> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = _parse(preferences.getString(lastImportPlatformKey));
    // A choice made while preferences were loading wins over the old value.
    if (_chosen) return state;
    if (mounted) state = saved;
    return saved;
  }

  Future<void> setPlatform(SocialPlatform platform) async {
    _chosen = true;
    state = platform;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(lastImportPlatformKey, platform.name);
  }

  static SocialPlatform? _parse(String? value) {
    if (value == null) return null;
    for (final platform in SocialPlatform.values) {
      if (platform.name == value) return platform;
    }
    return null;
  }
}
