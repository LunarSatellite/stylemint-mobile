/// **A hardcoded string may not tell the reader that something was picked for
/// them unless the data behind it says so.**
///
/// Generic content is not the problem. Labelling it as personal is. A
/// merchandised rail titled "Popular right now" is good product design; the
/// same rail titled "Picked for you" is a claim about the reader that nothing
/// in the system made.
///
/// The Discover lead feed carried exactly that claim: `ForYouFeedSource` is
/// built from `GET /api/v1/public/home` — a **public** page with no
/// `slotKind`, no score and no rank — plus the bestselling listing, and it
/// titled its blocks "Picked for you" and "More picks for you". A widget test
/// pins one screen; this reads the source, so the phrase cannot return as a
/// default somewhere else in the same file, or in the next file like it.
///
/// ## Scope
///
/// The scan walks **every** `.dart` file under `lib/` rather than a
/// hand-written list of directories, for the same reason the product-photo
/// guard does: a directory list only ever describes the app as it was on the
/// day someone wrote it. Exemptions are named individually below, each with
/// its reason.
///
/// ## Where the line is drawn
///
/// The rule fires on **string literals** containing a second-person
/// personalisation phrase. It does not fire on identifiers, field names or
/// comments: a doc comment that explains why a claim was removed must be free
/// to quote it, which is why `ForYouFeedSource` and `FeedSlotKind` can spell
/// out the sentences they exist to prevent.
///
/// A wire value *is* a string literal, so `slotKind: 'personalized'` does
/// trip the scan. Rather than invent a rule to tell contract tokens from copy
/// — a rule that would eventually let a real claim through — the two files
/// that parse those tokens are named in [_exemptions] like everything else.
///
/// It also does not fire on second-person copy that is *about the reader's own
/// action or property* rather than about content provenance: "your order",
/// "your return", "your basket", "waiting for you". Those are true by
/// construction. What it catches is the family that asserts something chose
/// this content **because of who is reading** — see [_claimPhrases].
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The phrases that assert a selection was made for the reader.
///
/// Each is matched case-insensitively and **on word boundaries** inside a
/// string literal. The boundaries matter: "for you" is a claim about the
/// reader, while "for your protection", "for your security" and "for your
/// StyleMint parcel" are statements about the reader's own things and are not
/// claims about how any content was chosen. A bare substring match conflated
/// the two and flagged four innocent files.
///
/// They are the vocabulary this codebase actually shipped, plus the near
/// neighbours it would reach for next — including the ones that are the same
/// claim wearing a coat: "curated for you" and "handpicked", which sound
/// softer and assert exactly as much.
const List<String> _claimPhrases = [
  'for you',
  'picked for',
  'picks for',
  'your picks',
  'just for you',
  'made for you',
  'chosen for you',
  'selected for you',
  'curated for you',
  'handpicked',
  'hand-picked',
  'recommended for you',
  'based on your',
  'because you',
  'we thought',
  'you might like',
  'you may like',
  'tailored to you',
  'matches your',
  'personalised for',
  'personalized for',
  // The bare adjective is the same claim in one word. It is deliberately
  // here even though it also matches the two wire-value files below: naming
  // those two by hand is cheaper than a clever rule that would one day let a
  // real claim through.
  'personalised',
  'personalized',
];

/// Files where a match is legitimate, each with the reason it is legitimate.
///
/// An entry here is a claim someone checked, not a claim someone waived.
const Map<String, String> _exemptions = {
  // ── Wire values, not copy ───────────────────────────────────────────────
  // `'personalized'` here is a contract token the server sends and these
  // files parse. Nobody reads it. The honest-label vocabulary itself lives in
  // feed_provenance.dart, which is where the shipped labels are defined.
  'lib/features/customer/discovery/domain/entities/feed_provenance.dart':
      'Parses the `slotKind` wire values and defines the honest labels.',
  'lib/features/customer/mall_home/data/models/storefront_layout_dto.dart':
      'Parses the storefront-layout `status` wire values.',

  // ── Server-sent content, rendered as sent ───────────────────────────────
  // `reason` is a free-text line the Mall home contract sends ("Because you
  // follow X"). It is content, not a client claim, and the client neither
  // writes nor rewrites it.
  'lib/features/customer/mall_home/presentation/adaptive_layout.dart':
      'Builds a reason line only from a real server-sent category label, and '
      'only when the server left the line empty.',

  // ── Claims backed by the reader's own explicit input ────────────────────
  // The customer types the mission brief (occasion, aesthetic, priority,
  // budget) and the server plans against it. An edit built to a brief the
  // customer just wrote really was made for them.
  'lib/features/customer/discovery/presentation/screens/mission_shopping_screen.dart':
      'Plan is built from the mission brief the customer just submitted.',
  // Derived from this customer's own order history.
  'lib/features/customer/orders/presentation/widgets/buy_it_again_section.dart':
      "Restock forecast is computed from the customer's own past orders.",
  'lib/features/customer/orders/presentation/screens/buy_it_again_screen.dart':
      'Same order-history basis, plus the Memory Vault opt-out copy.',
  // Sponsored placement names the customer's own search term, verbatim.
  'lib/features/customer/discovery/presentation/widgets/sponsored_badge.dart':
      'Discloses the actual search term the customer typed.',
  // Request carries the reel's platform + post id; the suggestions really are
  // for that reel.
  'lib/features/creator/reel_import/presentation/screens/tag_products_screen.dart':
      'Suggestions are requested for this specific reel by platform + post id.',
  // "Added for you" describes an action the app just took, not a selection.
  'lib/features/creator/reel_import/presentation/widgets/caption_standard_sheet.dart':
      'Describes an action the app performed, not a selection for the reader.',
  'lib/features/creator/reel_import/presentation/screens/import_reel_screen.dart':
      "Describes the import the app performs on the creator's behalf.",

  // ── Copy about the reader's own things, not about content provenance ────
  'lib/features/customer/orders/presentation/widgets/handover_delegation_card.dart':
      "About the reader's own parcel and their own delegate.",
  'lib/features/customer/orders/presentation/widgets/handover_delegation_copy.dart':
      "About the reader's own order matching the handover code.",
  'lib/features/customer/orders/presentation/widgets/handover_delegation_sheet.dart':
      "Asks what the reader's own delegate may accept on their behalf.",
  'lib/features/customer/orders/presentation/widgets/delivery_recovery_offers_view.dart':
      "Offers to act on the reader's own delivery.",
  'lib/features/customer/mall_home/presentation/widgets/mall_home_states.dart':
      'Empty-state invitation; claims nothing about any content.',
  'lib/features/customer/assistant/presentation/screens/assistant_conversation_screen.dart':
      'States what the assistant will NOT do (§5.9 disclaimer).',
  'lib/features/customer/cart/presentation/widgets/basket_insights_card.dart':
      'Discloses that the suggestion is NOT based on the basket.',
  'lib/features/creator/reel_studio/presentation/widgets/studio_insights_section.dart':
      "Creator-scoped studio endpoints keyed to this creator's own reels.",
  'lib/features/profile/presentation/screens/edit_profile_screen.dart':
      'Describes what a profile field and a marketing consent toggle are for.',
  // Onboarding copy promising a real feature, not labelling content. The
  // promise is backed by `FeedSlotKind.personalized` ("From your interests"),
  // which is driven by the categories and creators the customer chooses to
  // follow on these very screens. It describes what signing up gets you; it
  // does not tell the reader that anything already on screen was picked.
  'lib/features/customer/discovery/presentation/screens/follow_creators_discovery_screen.dart':
      "Promises a consequence of the reader's own explicit follows.",
  'lib/features/onboarding/presentation/screens/follow_creators_screen.dart':
      'Same promise, on the onboarding copy of the follow step.',
  'lib/features/auth/presentation/screens/user_type_selection_screen.dart':
      'Sign-up blurb describing the shopper account, before any content '
      'exists to mislabel.',
  'lib/features/support/shared/help_center_data.dart':
      'Help article text about custom-made products and 2FA setup.',

  // ── Fixture / mock data standing in for server content ──────────────────
  'lib/features/profile/shared/profile_mock_data.dart':
      "A creator's own self-written bio, standing in for server content.",
  'lib/features/customer/reels/shared/reels_mock_data.dart':
      'A creator\'s own reel caption ("my top 3 picks for dry skin"), in the '
      "creator's voice — not the app telling the reader anything.",
};

/// [_claimPhrases] compiled with word boundaries, in the same order.
final List<RegExp> _claimPatterns = [
  for (final phrase in _claimPhrases)
    RegExp('\\b${RegExp.escape(phrase)}\\b', caseSensitive: false),
];

final RegExp _stringLiteral = RegExp(
  // Single- and double-quoted Dart literals, non-greedy, escapes skipped.
  r"'''(?:[\s\S]*?)'''|"
  r'"""(?:[\s\S]*?)"""|'
  r"'(?:\\.|[^'\\\n])*'|"
  r'"(?:\\.|[^"\\\n])*"',
);

/// Strips `//` and `/* */` comments so a doc comment explaining a removed
/// claim is not itself flagged. Crude but sufficient: it only has to avoid
/// false positives, and a `//` inside a literal is handled by scanning
/// literals first.
String _withoutComments(String source) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final literal = _stringLiteral.matchAsPrefix(source, i);
    if (literal != null) {
      buffer.write(literal.group(0));
      i += literal.group(0)!.length;
      continue;
    }
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      i = end == -1 ? source.length : end;
      continue;
    }
    if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      i = end == -1 ? source.length : end + 2;
      continue;
    }
    buffer.write(source[i]);
    i++;
  }
  return buffer.toString();
}

void main() {
  test('no hardcoded string claims content was picked for the reader', () {
    final root = Directory('lib');
    expect(
      root.existsSync(),
      isTrue,
      reason: 'run from the package root so `lib/` resolves',
    );

    final offences = <String>[];
    final usedExemptions = <String>{};

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      // Generated code is not copy.
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;

      final source = _withoutComments(entity.readAsStringSync());
      final hits = <String>{};
      for (final match in _stringLiteral.allMatches(source)) {
        final literal = match.group(0)!;
        for (var i = 0; i < _claimPatterns.length; i++) {
          if (_claimPatterns[i].hasMatch(literal)) hits.add(_claimPhrases[i]);
        }
      }
      if (hits.isEmpty) continue;

      if (_exemptions.containsKey(path)) {
        usedExemptions.add(path);
        continue;
      }
      offences.add('$path → ${hits.join(', ')}');
    }

    expect(
      offences,
      isEmpty,
      reason:
          'These files hardcode a claim that content was picked for the '
          'reader. Either the data behind it supports the claim — then add an '
          'exemption above saying which field proves it — or relabel to what '
          'is true, reusing the shipped vocabulary: "Popular right now", '
          '"New in", "From your interests", "Something different", "From the '
          'Mall". Do not swap one unverified claim for a vaguer one: '
          '"Curated" and "Handpicked" are the same claim wearing a coat.\n'
          '${offences.join('\n')}',
    );

    // A stale exemption is a lie about the codebase, so it fails too.
    final stale = _exemptions.keys.toSet().difference(usedExemptions);
    expect(
      stale,
      isEmpty,
      reason:
          'These exemptions no longer match anything and should be deleted:\n'
          '${stale.join('\n')}',
    );
  });

  test('the phrases the fix removed are the ones the guard looks for', () {
    // If someone reintroduces either exact title, the scan must catch it.
    for (final removed in [
      'Picked for you',
      'More picks for you',
      'Recommended Brands for You',
      // And the softer synonyms: the same claim wearing a coat.
      'Curated for you',
      'Handpicked edit',
    ]) {
      expect(
        _claimPatterns.any((p) => p.hasMatch(removed)),
        isTrue,
        reason: '"$removed" must be caught by the scan',
      );
    }
    // Copy about the reader's own things is not a provenance claim, and the
    // word boundaries are what keep it out.
    for (final innocent in [
      'Sealed for your protection · tap to view',
      'For your security, Style Mint does not accept a local bank OTP.',
      'Waiting for your return',
    ]) {
      expect(
        _claimPatterns.any((p) => p.hasMatch(innocent)),
        isFalse,
        reason:
            '"$innocent" is about the reader, not about how content '
            'was chosen',
      );
    }
  });
}
