import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';

/// The single gate every part of the adaptive storefront passes through:
/// signed in, and not paused in the Memory Vault.
///
/// A guest has nothing to personalise from and no token to call with. A
/// customer who paused being remembered is not personalised *and* sends no
/// further signals — pausing has to stop the collecting, not only the using,
/// or the switch would be cosmetic. If the pause flag cannot be read at all,
/// this answers "paused": the quiet side of the doubt, and invisible either
/// way, because an unpersonalised Mall is the Mall.
class StorefrontPersonalizer {
  StorefrontPersonalizer({
    required AdaptiveStorefrontRepository storefront,
    required MemoryVaultRepository vault,
    required bool Function() isSignedIn,
    Duration consentTtl = const Duration(minutes: 5),
    DateTime Function() clock = _wallClock,
  }) : _storefront = storefront,
       _vault = vault,
       _isSignedIn = isSignedIn,
       _consentTtl = consentTtl,
       _clock = clock;

  static DateTime _wallClock() => DateTime.now();

  final AdaptiveStorefrontRepository _storefront;
  final MemoryVaultRepository _vault;
  final bool Function() _isSignedIn;
  final Duration _consentTtl;
  final DateTime Function() _clock;

  bool? _paused;
  DateTime? _pausedAt;

  /// Forgets the cached consent answer — called when the session changes or
  /// the customer touches the pause switch, so a change takes effect on the
  /// next load rather than in five minutes.
  void forgetConsent() {
    _paused = null;
    _pausedAt = null;
  }

  /// The layout for this customer, or [StorefrontLayout.none] for a guest,
  /// paused personalisation, a failed call or an empty ranking. Never throws.
  Future<StorefrontLayout> layout() async {
    if (!await allowed()) return StorefrontLayout.none;
    return _storefront.getLayout();
  }

  /// Records a signal, if there is someone to record it for and consent to do
  /// it. Fire-and-forget; never throws.
  Future<void> track(FeedSignal signal) async {
    // The signal's own constructors already refuse an invalid shape; this
    // only guards the id-shaped path against a blank that slipped through.
    if (!signal.isQueryShaped && (signal.entityId?.trim().isEmpty ?? true)) {
      return;
    }
    if (!await allowed()) return;
    await _storefront.trackInteraction(signal);
  }

  /// Whether this customer may be personalised right now.
  Future<bool> allowed() async {
    if (!_isSignedIn()) {
      forgetConsent();
      return false;
    }
    return !await _isPaused();
  }

  Future<bool> _isPaused() async {
    final cached = _paused;
    final at = _pausedAt;
    if (cached != null && at != null && _clock().difference(at) < _consentTtl) {
      return cached;
    }
    bool paused;
    try {
      // A failure to read consent counts as paused, and is not cached: the
      // next attempt asks again rather than muting the feature for the rest
      // of the session.
      final result = await _vault.isPaused();
      paused = result.fold((_) => true, (value) => value);
      if (result.isRight()) {
        _paused = paused;
        _pausedAt = _clock();
      }
    } on Object catch (_) {
      paused = true;
    }
    return paused;
  }
}
