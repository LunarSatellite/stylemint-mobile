import 'package:flutter/foundation.dart';

/// Why a multimodal search input (voice, barcode) can or cannot be used.
///
/// The Mall offers three ways into search — type, photo, and now speak or
/// scan. Every one of them can be missing on a real handset, so each input
/// carries one of these and the UI is driven from it rather than from a bare
/// `try { } catch { }` around the plugin call.
enum SearchInputStatus {
  /// Not probed yet. The entry point is still offered so the system
  /// permission prompt happens in context, on the first deliberate tap,
  /// rather than when Discover first paints.
  unprobed,

  /// Usable right now.
  ready,

  /// Refused for this attempt. Asking again is allowed, so the recovery is
  /// an in-app "Allow" button that re-triggers the system prompt.
  denied,

  /// Refused for good ("Don't ask again" / iOS deny). Only the system
  /// settings screen can undo it.
  deniedForever,

  /// Blocked by device policy, a work profile, or parental controls. The
  /// buyer personally cannot grant it, but the settings screen is still
  /// where an administrator would.
  restricted,

  /// There is no engine, no camera, or no usable locale. Nothing to grant
  /// and nothing to recover — the entry point must stop being offered.
  unsupported;

  /// Whether Discover should show this input's button at all.
  ///
  /// [unsupported] is the only status that hides it: every other status
  /// leads to a screen that explains itself and offers a way forward, and
  /// hiding those would leave the buyer with no route back to the setting
  /// they turned off.
  bool get isOffered => this != SearchInputStatus.unsupported;

  /// True when the block is a permission the buyer or an administrator can
  /// still change from the system settings screen.
  bool get opensSystemSettings =>
      this == SearchInputStatus.deniedForever ||
      this == SearchInputStatus.restricted;

  /// True when re-asking in-app can still produce a system prompt.
  bool get canAskAgain =>
      this == SearchInputStatus.denied || this == SearchInputStatus.unprobed;
}

/// The live availability of every multimodal search input.
@immutable
class SearchInputCapabilities {
  const SearchInputCapabilities({
    this.voice = SearchInputStatus.unprobed,
    this.barcode = SearchInputStatus.unprobed,
  });

  final SearchInputStatus voice;
  final SearchInputStatus barcode;

  SearchInputCapabilities copyWith({
    SearchInputStatus? voice,
    SearchInputStatus? barcode,
  }) => SearchInputCapabilities(
    voice: voice ?? this.voice,
    barcode: barcode ?? this.barcode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchInputCapabilities &&
          other.voice == voice &&
          other.barcode == barcode;

  @override
  int get hashCode => Object.hash(voice, barcode);
}
