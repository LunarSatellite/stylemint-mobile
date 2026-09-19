import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';

/// The single gate every part of the adaptive storefront passes through.
///
/// Three questions, asked in this order, and all three must say yes:
///
/// 1. **Signed in.** A guest has nothing to personalise from and no token to
///    call with, so nothing is read and nothing is asked.
/// 2. **Not paused in the Memory Vault.** The global pause is the blunt
///    instrument and it stays authoritative: it overrides every per-purpose
///    grant, and while it is on the per-purpose decisions are not read at
///    all — the backend reports `consent.paused` for all four regardless of
///    the answers underneath, so there is nothing there to learn.
/// 3. **[MemoryPurpose.storefrontPersonalisation] is permitted.** This is
///    the purpose the consent screen names, in the customer's own words,
///    and a refusal there has to stop the thing it names. Until this was
///    consulted, refusing recorded the refusal and changed nothing.
///
/// Anything short of a live decision is a no: refused, lapsed, never asked,
/// not reported by the backend at all, or unreadable. Absence is not
/// consent, and neither is doubt — if the decision cannot be read, nothing
/// is personalised and nothing is collected.
///
/// The gate covers the collecting as well as the using. A refusing customer
/// is not personalised *and* sends no further signals, because a refusal
/// that stopped the output while the harvesting carried on would be the same
/// defect wearing a nicer face.
///
/// Every "no" — guest, pause, refusal, failed read — answers identically and
/// invisibly with [StorefrontLayout.none], which leaves the Mall exactly as
/// everyone else sees it. Nothing here surfaces an error, an empty state, or
/// an invitation to switch it back on.
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

  /// The last answer that could actually be read, and when. A failed read is
  /// deliberately never stored: it refuses now and asks again next time,
  /// rather than muting the feature for the rest of the session.
  bool? _permitted;
  DateTime? _permittedAt;

  /// Forgets the cached answer — called when the session changes, when the
  /// customer touches the global pause, and when they allow or refuse the
  /// storefront purpose, so a decision takes effect on the next load rather
  /// than whenever the cache happens to lapse.
  void forgetConsent() {
    _permitted = null;
    _permittedAt = null;
  }

  /// The layout for this customer, or [StorefrontLayout.none] for a guest, a
  /// pause, a refused or undecided purpose, an unreadable decision, a failed
  /// call or an empty ranking. Never throws.
  Future<StorefrontLayout> layout() async {
    if (!await allowed()) return StorefrontLayout.none;
    return _storefront.getLayout();
  }

  /// Records a signal, if there is someone to record it for and consent to
  /// do it. Fire-and-forget; never throws.
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
    final cached = _permitted;
    final at = _permittedAt;
    if (cached != null && at != null && _clock().difference(at) < _consentTtl) {
      return cached;
    }
    final answer = await _decide();
    if (answer.readable) {
      _permitted = answer.permitted;
      _permittedAt = _clock();
    }
    return answer.permitted;
  }

  /// The gate below the sign-in check, and whether it could be read at all.
  /// An unreadable answer refuses without being remembered.
  Future<({bool permitted, bool readable})> _decide() async {
    final paused = await _globalPause();
    if (paused == null) return (permitted: false, readable: false);
    if (paused) return (permitted: false, readable: true);

    final consents = await _consents();
    if (consents == null) return (permitted: false, readable: false);
    return (permitted: _permitsStorefront(consents), readable: true);
  }

  /// The global pause, or null when it could not be read.
  Future<bool?> _globalPause() async {
    try {
      return (await _vault.isPaused()).toNullable();
    } on Object catch (_) {
      return null;
    }
  }

  /// Every purpose's current decision, or null when they could not be read.
  Future<List<MemoryConsent>?> _consents() async {
    try {
      return (await _vault.loadConsents()).toNullable();
    } on Object catch (_) {
      return null;
    }
  }

  /// Whether the storefront purpose is live, given the pause is already off.
  ///
  /// [MemoryConsent.permitted] is the one field the backend allows a caller
  /// to branch on, and the standing is read beside it so a paused or
  /// unreadable row can never arrive here as a yes.
  static bool _permitsStorefront(List<MemoryConsent> consents) {
    for (final consent in consents) {
      if (consent.purpose != MemoryPurpose.storefrontPersonalisation) {
        continue;
      }
      return switch (consent.standing) {
        // An explicit grant, or the legacy global-pause basis the two older
        // purposes still run on until the customer answers — and that pause
        // has already been checked, and is off.
        ConsentStanding.granted ||
        ConsentStanding.legacyBasis => consent.permitted,
        // Refused, lapsed, never asked, paused, unreadable, or a reason this
        // build does not recognise. Every one of them is a no.
        _ => false,
      };
    }
    // The backend did not report this purpose. Absence is not consent.
    return false;
  }
}
