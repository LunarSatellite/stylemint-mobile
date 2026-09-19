// Dense product copy and immutable parser factories are intentionally kept together.
// ignore_for_file: lines_longer_than_80_chars, sort_constructors_first

/// **The lifecycle steward, after the 730-day fabrication was removed.**
///
/// `estimatedRemainingLifeDays` used to be "730 minus the item's age", applied
/// to every product in the catalogue — a lifespan nobody measured, printed to
/// every customer as though someone had. The field is now `int?` and is never
/// populated, and the server says why through `expectedLifeSource`.
///
/// This screen therefore **does not parse that field at all**. Not into a
/// nullable, not into a `?? 0`. A value that cannot reach the widget tree
/// cannot be rendered by accident, and replacing one invented number with
/// another (a zero, or the warranty's day count) would be the same lie with
/// better manners. See `lifecycle_steward_screen_test.dart`, which asserts
/// over the rendered text that no life-estimate string can be produced.
///
/// What is rendered instead is only what the server measured:
///
/// * the **return window**, when it is still open;
/// * the seller's **warranty cover**, as cover — a promise about faults, with
///   an end date — and never as a remaining life;
/// * **not assessed**, said plainly, when neither applies.
///
/// Pathways are shown whether or not they can happen. Resale and trade-in are
/// structurally impossible here (the platform cannot tell one physical unit
/// from another) and the backend refuses to start them, so they render with
/// their reason and **no button**. A chip that posts a request the server will
/// reject is worse than no chip at all.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ---------------------------------------------------------------------------
// Wire vocabulary. Mirrors LifecycleRecommendations, CircularPathwayStatuses,
// CircularPathwayExecutors, CircularPathwayBlockers and LifecycleSources in
// StyleMint.Modules.Orders. Every switch over these has an explicit unknown
// arm — a value this build has never heard of must read as unknown, not fall
// into whichever branch happens to be last.
// ---------------------------------------------------------------------------

abstract final class LifecycleStates {
  static const String returnWindowOpen = 'return_window_open';
  static const String warrantyActive = 'warranty_active';
  static const String notAssessed = 'not_assessed';
}

abstract final class LifecyclePathwayStatuses {
  static const String available = 'available';
  static const String humanRequired = 'human_required';
  static const String providerRequired = 'provider_required';
  static const String requiresUnitIdentity = 'requires_unit_identity';
}

abstract final class LifecyclePathwayExecutors {
  static const String platform = 'platform';
  static const String person = 'person';
  static const String nobody = 'nobody';
}

abstract final class LifecycleBlockers {
  static const String unitIdentityAbsent = 'unitIdentity.absent';
  static const String providerNotConfigured = 'provider.notConfigured';
  static const String pricingHumanOnly = 'pricing.humanOnly';
}

abstract final class LifecycleSources {
  static const String notMeasured = 'notMeasured';
  static const String vendorDeclaredWarrantyPolicy =
      'vendorDeclaredWarrantyPolicy';
}

abstract final class LifecycleIdentityScopes {
  static const String orderLine = 'orderLine';
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final FutureProvider<List<LifecycleAsset>> lifecycleAssetsProvider =
    FutureProvider.autoDispose<List<LifecycleAsset>>((ref) async {
      final response = await ref
          .watch(apiClientProvider)
          .get('/v1/customer/lifecycle/assets');
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecycleAsset.fromJson)
          .toList(growable: false);
    });

/// The item-independent capability register, `GET v1/customer/lifecycle/pathways`.
///
/// Rendered on the empty wardrobe so a customer with nothing delivered still
/// learns what this platform can and cannot arrange, rather than inferring
/// from an absence of chips that the feature is coming.
final FutureProvider<List<LifecyclePathway>> lifecyclePathwayRegisterProvider =
    FutureProvider.autoDispose<List<LifecyclePathway>>((ref) async {
      final response = await ref
          .watch(apiClientProvider)
          .get('/v1/customer/lifecycle/pathways');
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecyclePathway.fromJson)
          .toList(growable: false);
    });

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// The seller's declared warranty, as cover.
///
/// Held in its own object so it can never be mistaken for a life figure at a
/// call site: there is no field on [LifecycleAsset] that a careless
/// `?? 0` could turn back into "days left".
@immutable
class LifecycleWarranty {
  const LifecycleWarranty({
    required this.coverEndsUtc,
    required this.coverageDays,
    required this.coverageRemainingDays,
    required this.source,
  });

  /// When the seller's cover stops applying. Not when the item stops working.
  final DateTime? coverEndsUtc;
  final int? coverageDays;
  final int? coverageRemainingDays;
  final String? source;

  bool get isActive => (coverageRemainingDays ?? 0) > 0;

  /// Null when the seller declared no policy at all. Absence is absence: the
  /// server sends nulls rather than a zero-day cover, and so does this.
  static LifecycleWarranty? fromJson(Map<String, dynamic> json) {
    final endsUtc = _date(json['warrantyCoverageEndsUtc']);
    final days = _int(json['warrantyCoverageDays']);
    final remaining = _int(json['warrantyCoverageRemainingDays']);
    final source = json['warrantySource'] as String?;
    if (endsUtc == null &&
        days == null &&
        remaining == null &&
        source == null) {
      return null;
    }
    return LifecycleWarranty(
      coverEndsUtc: endsUtc,
      coverageDays: days,
      coverageRemainingDays: remaining,
      source: source,
    );
  }
}

@immutable
class LifecycleAsset {
  const LifecycleAsset({
    required this.lineId,
    required this.title,
    required this.variant,
    required this.ageDays,
    required this.quantity,
    required this.state,
    required this.reason,
    required this.expectedLifeSource,
    required this.identityScope,
    required this.identityScopeExplanation,
    required this.returnWindowClosesUtc,
    required this.warranty,
    required this.pathways,
  });

  final String lineId;
  final String title;
  final String? variant;
  final int ageDays;

  /// How many physical objects this one row stands for. The platform cannot
  /// tell them apart; see [identityScopeExplanation].
  final int quantity;

  /// One of [LifecycleStates], or something this build has not heard of.
  final String state;
  final String reason;

  /// [LifecycleSources.notMeasured] today, and the reason no life is shown.
  final String expectedLifeSource;
  final String identityScope;
  final String identityScopeExplanation;
  final DateTime? returnWindowClosesUtc;
  final LifecycleWarranty? warranty;
  final List<LifecyclePathway> pathways;

  /// True while nobody has measured an expected life for this item — which is
  /// every item, today. Gated rather than assumed, so that if a real, sourced
  /// expected life ever appears the screen falls silent instead of printing a
  /// sentence that has quietly become false.
  bool get lifeIsUnmeasured =>
      expectedLifeSource == LifecycleSources.notMeasured;

  /// The identity caveat is worth spending a customer's attention on when the
  /// row stands for more than one object: everything else on the card is then
  /// being said about a group, not a thing.
  bool get identityCaveatMatters => quantity > 1;

  /// Note the absence of `estimatedRemainingLifeDays`. It is deliberate and
  /// load-bearing: the server always sends null, and a field here is all it
  /// would take for the fabrication to grow back as `?? 0`.
  factory LifecycleAsset.fromJson(Map<String, dynamic> json) => LifecycleAsset(
    lineId: json['subOrderLineId'] as String? ?? '',
    title: json['title'] as String? ?? 'Your item',
    variant: json['variantLabel'] as String?,
    ageDays: _int(json['ageDays']) ?? 0,
    quantity: _int(json['quantity']) ?? 1,
    state: json['recommendation'] as String? ?? '',
    reason: json['recommendationReason'] as String? ?? '',
    expectedLifeSource: json['expectedLifeSource'] as String? ?? '',
    identityScope: json['identityScope'] as String? ?? '',
    identityScopeExplanation: json['identityScopeExplanation'] as String? ?? '',
    returnWindowClosesUtc: _date(json['returnWindowClosesUtc']),
    warranty: LifecycleWarranty.fromJson(json),
    pathways: (json['pathways'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LifecyclePathway.fromJson)
        .toList(growable: false),
  );
}

@immutable
class LifecyclePathway {
  const LifecyclePathway({
    required this.kind,
    required this.available,
    required this.status,
    required this.explanation,
    required this.carriedOutBy,
    required this.blockers,
  });

  final int kind;
  final bool available;

  /// One of [LifecyclePathwayStatuses], or unknown.
  final String status;
  final String explanation;

  /// One of [LifecyclePathwayExecutors], or unknown. `nobody` is the server
  /// saying out loud that no human being has a route either.
  final String carriedOutBy;

  /// Stable codes from [LifecycleBlockers]. Branchable without parsing prose.
  final List<String> blockers;

  factory LifecyclePathway.fromJson(Map<String, dynamic> json) =>
      LifecyclePathway(
        kind: json['pathway'] is num
            ? (json['pathway'] as num).toInt()
            : _kind(json['pathway']?.toString()),
        available: json['available'] as bool? ?? false,
        status: json['status'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        carriedOutBy: json['carriedOutBy'] as String? ?? '',
        blockers: (json['blockers'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  static int _kind(String? value) =>
      switch (value?.toLowerCase().replaceAll(RegExp('[ _-]'), '')) {
        'repair' => 1,
        'tradein' => 2,
        'resale' => 3,
        'recycle' => 4,
        _ => 0,
      };

  String get label => switch (kind) {
    1 => 'Repair',
    2 => 'Trade in',
    3 => 'Resell',
    4 => 'Recycle',
    _ => 'Another route',
  };

  IconData get icon => switch (kind) {
    1 => Icons.handyman_outlined,
    2 => Icons.swap_horiz_rounded,
    3 => Icons.sell_outlined,
    4 => Icons.recycling_rounded,
    _ => Icons.eco_outlined,
  };

  String get actionLabel => switch (kind) {
    1 => 'Ask for a repair',
    4 => 'Ask to recycle',
    _ => 'Ask about this route',
  };

  bool get blockedByUnitIdentity =>
      blockers.contains(LifecycleBlockers.unitIdentityAbsent);
  bool get blockedByPricing =>
      blockers.contains(LifecycleBlockers.pricingHumanOnly);
  bool get blockedByProvider =>
      blockers.contains(LifecycleBlockers.providerNotConfigured);

  /// Whether to offer a button at all.
  ///
  /// **Fails closed.** An executor or a status this build does not recognise
  /// buys no benefit of the doubt: the button is withheld and the row still
  /// explains itself. Offering an action the server then refuses is the shape
  /// of promise this screen exists to stop making — and §5.9 keeps
  /// [LifecycleBlockers.pricingHumanOnly] out of reach whatever else is true.
  bool get canBeRequested {
    if (carriedOutBy != LifecyclePathwayExecutors.platform &&
        carriedOutBy != LifecyclePathwayExecutors.person) {
      return false;
    }
    if (blockedByUnitIdentity || blockedByPricing) return false;
    return available ||
        status == LifecyclePathwayStatuses.humanRequired ||
        status == LifecyclePathwayStatuses.providerRequired;
  }

  /// Glyph and word, never colour alone.
  ({String label, IconData icon, MallStatusTone tone}) get statusView =>
      switch (status) {
        LifecyclePathwayStatuses.available => (
          label: 'Available now',
          icon: Icons.check_circle_outline,
          tone: MallStatusTone.success,
        ),
        LifecyclePathwayStatuses.humanRequired => (
          label: 'A person handles this',
          icon: Icons.person_outline,
          tone: MallStatusTone.info,
        ),
        LifecyclePathwayStatuses.providerRequired => (
          label: 'No partner yet',
          icon: Icons.pending_outlined,
          tone: MallStatusTone.caution,
        ),
        LifecyclePathwayStatuses.requiresUnitIdentity => (
          label: 'Not possible yet',
          icon: Icons.do_not_disturb_on_outlined,
          tone: MallStatusTone.neutral,
        ),
        _ => (
          label: 'Status not recognised',
          icon: Icons.help_outline_rounded,
          tone: MallStatusTone.neutral,
        ),
      };

  /// The one-line version, in the customer's terms, of why this is blocked.
  /// The server's own [explanation] follows it and carries the detail.
  String? get blockerLead {
    if (blockedByUnitIdentity) {
      return blockedByPricing
          ? 'We cannot yet tell your item apart from an identical one, so we cannot pass on that exact object — and a trade-in figure is money, which nobody here sets automatically.'
          : 'We cannot yet tell your item apart from an identical one, so we cannot pass on that exact object as the one you bought.';
    }
    if (blockedByPricing) {
      return 'A figure in money is involved, and nobody here sets one automatically.';
    }
    if (blockedByProvider) {
      return 'No verified partner is signed up for this yet, so nothing can be booked. What you ask for is written down for a person to take forward.';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// The three states, plus an honest fourth for anything newer than this build.
// ---------------------------------------------------------------------------

@immutable
class LifecycleStateView {
  const LifecycleStateView({
    required this.label,
    required this.icon,
    required this.tone,
    required this.lead,
  });

  final String label;
  final IconData icon;
  final MallStatusTone tone;

  /// What the state means, in one sentence of ours. The server's
  /// `recommendationReason` follows with the measured detail.
  final String lead;
}

/// Maps a wire state onto what the card shows.
///
/// The final arm is not a fall-through — it is a fourth, visibly different
/// rendering that says the app does not know this value. When
/// `do_not_replace_yet` vanished from the contract, the old screen's
/// two-branch `keep ? … : …` silently re-labelled every card in the wardrobe
/// "Assess next life". Nothing here can do that again: an unrecognised state
/// reads as unrecognised.
LifecycleStateView lifecycleStateView(String state) => switch (state) {
  LifecycleStates.returnWindowOpen => const LifecycleStateView(
    label: 'Return window open',
    icon: Icons.assignment_return_outlined,
    tone: MallStatusTone.info,
    lead: 'You can still send this back.',
  ),
  LifecycleStates.warrantyActive => const LifecycleStateView(
    label: 'Warranty cover active',
    icon: Icons.verified_user_outlined,
    tone: MallStatusTone.success,
    lead: "The seller's cover still applies to a fault.",
  ),
  LifecycleStates.notAssessed => const LifecycleStateView(
    label: 'Not assessed',
    icon: Icons.remove_circle_outline,
    tone: MallStatusTone.neutral,
    lead:
        'StyleMint is not advising for or against replacing this, because it '
        'has measured nothing that would support either.',
  ),
  _ => const LifecycleStateView(
    label: 'Status not recognised',
    icon: Icons.help_outline_rounded,
    tone: MallStatusTone.neutral,
    lead:
        'This version of the app does not recognise the status sent for this '
        'item. Updating StyleMint should show it.',
  ),
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LifecycleStewardScreen extends ConsumerWidget {
  const LifecycleStewardScreen({super.key});

  static const ValueKey<String> portfolioKey = ValueKey<String>(
    'lifecycle-portfolio',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(lifecycleAssetsProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('My wardrobe life'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: assets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Empty(
          icon: Icons.cloud_off_rounded,
          title: 'Wardrobe unavailable',
          body: 'Check your connection and try again.',
          onTap: () => ref.invalidate(lifecycleAssetsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(lifecycleAssetsProvider.future),
          child: ListView(
            key: portfolioKey,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
            children: [
              const _Hero(),
              const SizedBox(height: DesignTokens.s16),
              if (items.isEmpty) ...const [
                _Empty(
                  icon: Icons.checkroom_outlined,
                  title: 'Nothing delivered yet',
                  body:
                      'Items appear here once they arrive, with what StyleMint '
                      'can actually check about them.',
                ),
                SizedBox(height: DesignTokens.s16),
                _PathwayRegister(),
              ] else
                for (final item in items) ...[
                  _AssetCard(item),
                  const SizedBox(height: DesignTokens.s16),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      color: DesignTokens.primaryGreenDark,
      boxShadow: DesignTokens.shadowCard,
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.eco_rounded, color: DesignTokens.primaryGreen, size: 34),
        SizedBox(height: DesignTokens.s12),
        Text(
          'What we actually know',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        SizedBox(height: DesignTokens.s8),
        // The old copy here promised StyleMint "will never push a replacement
        // while useful life remains" — a promise that quietly asserted the
        // platform knew how much life remained. It never did.
        Text(
          'Nobody has measured how long these items last, so StyleMint does '
          'not guess. It shows you the things it can check: whether your '
          'return window is open, what cover the seller declared, and which '
          'routes it can genuinely arrange.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.45),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Asset card
// ---------------------------------------------------------------------------

class _AssetCard extends ConsumerWidget {
  const _AssetCard(this.asset);

  final LifecycleAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = lifecycleStateView(asset.state);
    // No photograph. Product photos live on product detail (owner directive,
    // 2026-09-16), and a 170px hero of a garment the buyer already owns costs
    // the card the vertical space these facts need at large text sizes.
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: Colors.white,
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s4,
            children: [
              if (asset.variant case final variant?
                  when variant.trim().isNotEmpty)
                _Meta(variant),
              _Meta(
                asset.quantity == 1 ? '1 item' : '${asset.quantity} items',
              ),
              _Meta('Delivered ${_ageLabel(asset.ageDays)}'),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),

          // ---- The state -------------------------------------------------
          MallStatusPill(
            label: view.label,
            tone: view.tone,
            icon: view.icon,
            semanticLabel: '${asset.title}. Status: ${view.label}',
          ),
          const SizedBox(height: DesignTokens.s8),
          _Body(view.lead, emphasis: true),
          if (asset.reason.trim().isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            _Body(asset.reason),
          ],
          if (asset.returnWindowClosesUtc case final closes?) ...[
            const SizedBox(height: DesignTokens.s8),
            _Fact(
              icon: Icons.event_available_outlined,
              label: 'Return window closes ${_date_(closes)}',
            ),
          ],

          // ---- No life estimate, said out loud ---------------------------
          if (asset.lifeIsUnmeasured) ...[
            const SizedBox(height: DesignTokens.s12),
            const _Divider(),
            const SizedBox(height: DesignTokens.s12),
            const _SectionLabel('How long it will last'),
            const SizedBox(height: DesignTokens.s4),
            // Deliberately numberless. This block is where the fabricated
            // "730 days minus age" used to be printed.
            const _Body(
              'Nobody has measured this. StyleMint holds no figure for how '
              'long this item lasts and will not invent one, so there is '
              'nothing here to read.',
            ),
          ],

          // ---- Warranty, as cover ----------------------------------------
          const SizedBox(height: DesignTokens.s12),
          const _Divider(),
          const SizedBox(height: DesignTokens.s12),
          const _SectionLabel('Warranty cover'),
          const SizedBox(height: DesignTokens.s8),
          _WarrantyBlock(asset.warranty),

          // ---- Identity scope, when it changes what is being said ---------
          if (asset.identityCaveatMatters) ...[
            const SizedBox(height: DesignTokens.s12),
            const _Divider(),
            const SizedBox(height: DesignTokens.s12),
            _IdentityCaveat(asset),
          ],

          // ---- Pathways ---------------------------------------------------
          const SizedBox(height: DesignTokens.s12),
          const _Divider(),
          const SizedBox(height: DesignTokens.s12),
          const _SectionLabel('What StyleMint can arrange'),
          const SizedBox(height: DesignTokens.s8),
          if (asset.pathways.isEmpty)
            const _Body('No routes were offered for this item.')
          else
            for (final pathway in asset.pathways) ...[
              _PathwayRow(
                pathway: pathway,
                onRequest: pathway.canBeRequested
                    ? () => _request(context, ref, asset, pathway)
                    : null,
                assetTitle: asset.title,
              ),
              const SizedBox(height: DesignTokens.s8),
            ],
        ],
      ),
    );
  }

  static String _ageLabel(int days) => switch (days) {
    <= 0 => 'today',
    1 => 'yesterday',
    _ => '$days days ago',
  };

  Future<void> _request(
    BuildContext context,
    WidgetRef ref,
    LifecycleAsset asset,
    LifecyclePathway pathway,
  ) async {
    final condition = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceRaised,
      builder: (_) => _ConditionSheet(pathway),
    );
    if (condition == null || !context.mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/v1/customer/lifecycle/assets/${asset.lineId}/requests',
            data: {'pathway': pathway.kind, 'condition': condition},
            options: Options(
              headers: {
                'requiresToken': true,
                'Idempotency-Key': 'lifecycle-${asset.lineId}-${pathway.kind}',
              },
            ),
          );
      if (!context.mounted) return;
      final state = response is Map<String, dynamic> ? response['state'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state == 3 || state == 'Accepted'
                ? '${pathway.label} request accepted by a partner.'
                : '${pathway.label} request written down. Nothing is booked and no price is quoted — a person takes it from here.',
          ),
        ),
      );
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this request. Please try again.'),
          ),
        );
      }
    }
  }
}

/// The seller's warranty, rendered as cover and only ever as cover.
///
/// Cover is a promise about faults with an end date on it. It is not a
/// prediction that the item stops working that day, and
/// `warrantyCoverageRemainingDays` is not a stand-in for the life figure that
/// was removed — so every string here is labelled "cover", and the block says
/// in as many words what the end date does and does not mean.
class _WarrantyBlock extends StatelessWidget {
  const _WarrantyBlock(this.warranty);

  final LifecycleWarranty? warranty;

  @override
  Widget build(BuildContext context) {
    final cover = warranty;
    if (cover == null) {
      return const _Body(
        'The seller declared no warranty for this item, so there is no cover '
        'to report. That is an absence of a policy, not a policy of no cover.',
      );
    }
    final active = cover.isActive;
    final ends = cover.coverEndsUtc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MallStatusPill(
          label: ends == null
              ? (active ? 'Cover active' : 'Cover status unclear')
              : '${active ? 'Cover ends' : 'Cover ended'} ${_date_(ends)}',
          tone: active ? MallStatusTone.success : MallStatusTone.neutral,
          icon: active ? Icons.verified_user_outlined : Icons.shield_outlined,
          semanticLabel: active
              ? 'Warranty cover active${ends == null ? '' : ', ends ${_date_(ends)}'}'
              : 'Warranty cover ended${ends == null ? '' : ' on ${_date_(ends)}'}',
        ),
        const SizedBox(height: DesignTokens.s8),
        if (cover.coverageDays case final days?)
          _Body(
            'The seller declared $days days of cover from delivery. Cover means '
            'the seller handles a fault under their own terms.',
          ),
        if (cover.coverageRemainingDays case final remaining? when active)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: _Body('About $remaining days of that cover are left.'),
          ),
        const SizedBox(height: DesignTokens.s4),
        _Body(
          ends == null
              ? 'When cover ends, the seller stops being responsible for faults. It says nothing about how long the item itself lasts.'
              : 'On ${_date_(ends)} the cover stops, not the item. The date is the end of the seller’s responsibility for a fault, and says nothing about how long the item lasts.',
        ),
        if (cover.source case final source? when source.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s4),
          _Footnote(
            source == LifecycleSources.vendorDeclaredWarrantyPolicy
                ? 'Stated by the seller in their own warranty policy.'
                : 'Stated by: $source.',
          ),
        ],
      ],
    );
  }
}

/// Says plainly that a line of quantity *n* is *n* objects nobody can tell
/// apart, so the customer reads everything above as being about the line.
class _IdentityCaveat extends StatelessWidget {
  const _IdentityCaveat(this.asset);

  final LifecycleAsset asset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MallStatusPill(
        label: 'One line, ${asset.quantity} items',
        tone: MallStatusTone.info,
        icon: Icons.layers_outlined,
        semanticLabel:
            'One order line covering ${asset.quantity} items the platform cannot tell apart',
      ),
      const SizedBox(height: DesignTokens.s8),
      _Body(
        asset.identityScopeExplanation.trim().isNotEmpty
            ? asset.identityScopeExplanation
            : 'These ${asset.quantity} arrived on one order line and nothing marks them individually, so everything above is said about the line rather than about one particular item.',
      ),
      if (asset.identityScope.isNotEmpty &&
          asset.identityScope != LifecycleIdentityScopes.orderLine) ...[
        const SizedBox(height: DesignTokens.s4),
        _Footnote('Recorded against: ${asset.identityScope}.'),
      ],
    ],
  );
}

/// One route, whether or not anybody can walk it.
///
/// An unavailable route keeps its name, its glyph and its reason, and loses
/// only the button. Hiding it would read as "not for this item" when the
/// truth is "this platform cannot do this for anything".
class _PathwayRow extends StatelessWidget {
  const _PathwayRow({
    required this.pathway,
    required this.onRequest,
    required this.assetTitle,
  });

  final LifecyclePathway pathway;
  final VoidCallback? onRequest;
  final String assetTitle;

  @override
  Widget build(BuildContext context) {
    final status = pathway.statusView;
    final lead = pathway.blockerLead;
    final action = onRequest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap, not Row: at 320dp and text scale 1.3 the name and the
          // status pill cannot share a line, and must be allowed to stack.
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pathway.icon,
                    size: 18,
                    color: DesignTokens.textLight,
                  ),
                  const SizedBox(width: DesignTokens.s6),
                  Text(
                    pathway.label,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              MallStatusPill(
                label: status.label,
                tone: status.tone,
                icon: status.icon,
                dense: true,
                semanticLabel: '${pathway.label}: ${status.label}',
              ),
            ],
          ),
          if (lead != null) ...[
            const SizedBox(height: DesignTokens.s8),
            _Body(lead, emphasis: true),
          ],
          if (pathway.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            _Footnote(pathway.explanation),
          ],
          if (action != null) ...[
            const SizedBox(height: DesignTokens.s12),
            // `onTap` is passed alongside `excludeSemantics` on purpose:
            // excluding the child drops the button's own tap action from the
            // semantics tree, which leaves a node a screen reader can read
            // but not activate. Restoring it here keeps one clean label and
            // a working control.
            Semantics(
              button: true,
              label: '${pathway.actionLabel} for $assetTitle',
              container: true,
              onTap: action,
              excludeSemantics: true,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: action,
                  child: Text(pathway.actionLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The item-independent register, for the empty wardrobe.
class _PathwayRegister extends ConsumerWidget {
  const _PathwayRegister();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final register = ref.watch(lifecyclePathwayRegisterProvider);
    final pathways = register.asData?.value ?? const <LifecyclePathway>[];
    if (pathways.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('What this platform can arrange'),
          const SizedBox(height: DesignTokens.s4),
          const _Body(
            'The same for every item, whatever you own. Routes are listed '
            'even when nobody can carry them out.',
          ),
          const SizedBox(height: DesignTokens.s12),
          for (final pathway in pathways) ...[
            // No buttons here: the register is item-independent, and there is
            // nothing to request without an item.
            _PathwayRow(
              pathway: pathway,
              onRequest: null,
              assetTitle: '',
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small parts
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      color: emphasis ? DesignTokens.textLight : DesignTokens.textMuted,
      fontSize: 13,
      height: 1.45,
      fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
    ),
  );
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      color: DesignTokens.textMuted,
      fontSize: 11.5,
      height: 1.4,
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      color: DesignTokens.textMuted,
      fontSize: 12,
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s6),
        Expanded(child: _Footnote(label)),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    width: double.infinity,
    child: ColoredBox(color: DesignTokens.bgAppBodyLight),
  );
}

class _ConditionSheet extends StatefulWidget {
  const _ConditionSheet(this.pathway);

  final LifecyclePathway pathway;

  @override
  State<_ConditionSheet> createState() => _ConditionSheetState();
}

class _ConditionSheetState extends State<_ConditionSheet> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pathway.actionLabel,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _Body(
            widget.pathway.available
                ? 'A verified partner is available for this route.'
                : 'Nothing is booked by sending this, and no price is quoted. It is written down for a person to take forward.',
          ),
          if (widget.pathway.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            _Footnote(widget.pathway.explanation),
          ],
          const SizedBox(height: DesignTokens.s16),
          Semantics(
            textField: true,
            label: 'What condition is the item in?',
            child: TextField(
              controller: controller,
              maxLength: 80,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'What condition is it in?',
                hintText: 'Example: good, one button missing',
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Semantics(
            button: true,
            label: 'Send this request',
            container: true,
            onTap: _submit,
            excludeSemantics: true,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Send request'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: DesignTokens.primaryGreen),
          const SizedBox(height: DesignTokens.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.textLight,
              height: 1.45,
            ),
          ),
          if (onTap case final retry?) ...[
            const SizedBox(height: DesignTokens.s12),
            Semantics(
              button: true,
              label: 'Try loading your items again',
              container: true,
              onTap: retry,
              excludeSemantics: true,
              child: TextButton(
                onPressed: retry,
                child: const Text('Try again'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Parsing and formatting helpers
// ---------------------------------------------------------------------------

int? _int(Object? value) => value is num ? value.toInt() : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Dates are shown in the reader's own zone; a UTC instant labelled with a
/// local-looking date is its own small untruth.
String _date_(DateTime value) =>
    DateFormat('d MMM yyyy').format(value.toLocal());
