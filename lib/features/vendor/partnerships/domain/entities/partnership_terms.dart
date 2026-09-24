/// The terms a vendor offers every creator they partner with.
///
/// One body per vendor, versioned server-side: publishing does not edit the
/// previous version, it supersedes it and rotates every live partnership onto
/// the new one. A creator reads them on the brand's Partnership Terms tab
/// before accepting.
///
/// Publishing these is a **precondition for partnering at all** — the backend
/// refuses both `POST /v1/vendor/partnerships/invite` and a creator's
/// `POST /v1/creator/partnerships/request` with "Vendor must publish
/// partnership terms before inviting a creator" until a version exists.
class PartnershipTerms {
  const PartnershipTerms({
    this.whoCanJoinHeading = defaultWhoCanJoinHeading,
    this.whoCanJoin = const <String>[],
    this.reelRulesHeading = defaultReelRulesHeading,
    this.reelRules = const <String>[],
  });

  /// Headings the creator-facing screen expects; the vendor may reword them.
  static const defaultWhoCanJoinHeading = 'Who Can Join';
  static const defaultReelRulesHeading = 'Reel Content Rules';

  /// Server limits (`WhoCanJoinSection` / `ReelContentRulesSection`). Mirrored
  /// here so the editor can stop an over-long bullet before the round trip
  /// rather than surfacing a 400 the vendor cannot act on.
  static const maxHeadingLength = 200;
  static const maxBulletLength = 1000;
  static const maxBullets = 20;

  final String whoCanJoinHeading;
  final List<String> whoCanJoin;
  final String reelRulesHeading;
  final List<String> reelRules;

  /// Something a creator can actually read and agree to. The server accepts an
  /// empty bullet list, but terms with no terms in them help nobody, so the
  /// editor requires one bullet in each section.
  bool get isPublishable =>
      whoCanJoinHeading.trim().isNotEmpty &&
      reelRulesHeading.trim().isNotEmpty &&
      whoCanJoin.any((b) => b.trim().isNotEmpty) &&
      reelRules.any((b) => b.trim().isNotEmpty);

  PartnershipTerms copyWith({
    String? whoCanJoinHeading,
    List<String>? whoCanJoin,
    String? reelRulesHeading,
    List<String>? reelRules,
  }) => PartnershipTerms(
    whoCanJoinHeading: whoCanJoinHeading ?? this.whoCanJoinHeading,
    whoCanJoin: whoCanJoin ?? this.whoCanJoin,
    reelRulesHeading: reelRulesHeading ?? this.reelRulesHeading,
    reelRules: reelRules ?? this.reelRules,
  );

  /// Wire shape of `PublishTermsVm`. Blank bullets are dropped rather than
  /// sent: the server rejects a blank bullet outright, and an empty row left
  /// behind in the editor is a vendor who stopped typing, not an error.
  ///
  /// `inlineLinks` is always empty — the server supports anchored links inside
  /// a rule, but this editor has no way to author the index ranges they need,
  /// and a wrong range would mislabel the text.
  Map<String, dynamic> toJson() => {
    'whoCanJoin': {
      'heading': whoCanJoinHeading.trim(),
      'bullets': _clean(whoCanJoin),
    },
    'reelContentRules': {
      'heading': reelRulesHeading.trim(),
      'bullets': [
        for (final rule in _clean(reelRules))
          {'text': rule, 'inlineLinks': const <Map<String, dynamic>>[]},
      ],
    },
  };

  static List<String> _clean(List<String> bullets) => [
    for (final b in bullets)
      if (b.trim().isNotEmpty) b.trim(),
  ];
}
