import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Lifecycle of a `BrandBrief` (Vendor §3): Draft → Locked (first invite
/// attaches) → Retired. Edits on a Locked brief require a new version via
/// Fork (not modelled here — the mobile UI doesn't fork briefs yet).
enum BrandBriefState { draft, locked, retired }

/// Mirrors `RoiProjectionSummary` (Vendor §5.4) — returned inline on
/// `BrandBriefDto.roiProjection` and standalone from
/// `POST /v1/vendor/briefs/{id}/recompute-roi`.
class RoiProjectionSummary {
  const RoiProjectionSummary({
    required this.estimatedReachCost,
    required this.estimatedReachLow,
    required this.estimatedReachHigh,
    required this.estimatedSalesLow,
    required this.estimatedSalesHigh,
    required this.estimatedRevenueLow,
    required this.estimatedRevenueHigh,
  });

  final Money estimatedReachCost;
  final int estimatedReachLow;
  final int estimatedReachHigh;
  final int estimatedSalesLow;
  final int estimatedSalesHigh;

  /// Same currency as [estimatedRevenueHigh] — render as a `Low–High` range.
  final Money estimatedRevenueLow;
  final Money estimatedRevenueHigh;
}

/// Mirrors `BrandBriefDto` from `GET/POST/PATCH /v1/vendor/briefs*` plus the
/// lifecycle actions (`lock`/`fork`/`retire`/`recompute-roi`) — the real
/// "campaign" concept on the backend is a Brand Studio brief. The JSONB
/// `body` of hooks/cadence/recipes is intentionally not modelled — the
/// mobile UI doesn't render it yet.
///
/// NOTE: previously this entity modelled `description`, a single
/// `commissionRate`, `startDate`/`endDate`, `targetCreators`, and
/// `requiredCategories` — none of which exist on the real endpoint.
class CampaignBrief {
  const CampaignBrief({
    required this.id,
    required this.vendorProfileId,
    this.title,
    required this.primaryGoal,
    required this.state,
    required this.version,
    required this.rootBriefId,
    this.parentBriefId,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.boostBudget,
    this.roiProjection,
    required this.createdAt,
    required this.updatedAt,
    this.lockedAt,
  });

  final String id;
  final String vendorProfileId;
  final String? title;

  /// Raw `CampaignGoal` enum value (1-7) — the backend doesn't publish
  /// display labels for these in the API contract.
  final int primaryGoal;
  final BrandBriefState state;

  /// Increments by one per fork; 1 for the original draft.
  final int version;

  /// Id of the original draft in this brief's lineage (`id` itself when
  /// `version == 1`).
  final String rootBriefId;

  /// Null for the original draft; the source brief's id when this version
  /// was created by forking that source brief.
  final String? parentBriefId;

  /// Fraction (0..1), not a whole percent — matches the backend's
  /// `CommissionRange` convention.
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final Money boostBudget;
  final RoiProjectionSummary? roiProjection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lockedAt;

  CampaignBrief copyWith({
    String? id,
    String? vendorProfileId,
    String? title,
    int? primaryGoal,
    BrandBriefState? state,
    int? version,
    String? rootBriefId,
    String? parentBriefId,
    double? commissionMinPercent,
    double? commissionMaxPercent,
    Money? boostBudget,
    RoiProjectionSummary? roiProjection,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lockedAt,
  }) {
    return CampaignBrief(
      id: id ?? this.id,
      vendorProfileId: vendorProfileId ?? this.vendorProfileId,
      title: title ?? this.title,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      state: state ?? this.state,
      version: version ?? this.version,
      rootBriefId: rootBriefId ?? this.rootBriefId,
      parentBriefId: parentBriefId ?? this.parentBriefId,
      commissionMinPercent: commissionMinPercent ?? this.commissionMinPercent,
      commissionMaxPercent: commissionMaxPercent ?? this.commissionMaxPercent,
      boostBudget: boostBudget ?? this.boostBudget,
      roiProjection: roiProjection ?? this.roiProjection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }
}

/// Mirrors `CreatorPickerDto` from `GET /v1/vendor/partnerships/creators`
/// (Vendor §7J — the invite picker). NOTE: previously this entity was
/// shaped like a `Partnership` record (campaignId, status, invitedAt) —
/// those fields don't exist on the picker endpoint; a creator's actual
/// invite/partnership state is a separate resource (`PartnershipDto`) with
/// no creator display fields at all.
class CreatorInvite {
  const CreatorInvite({
    required this.creatorAccountId,
    this.displayName,
    this.handle,
    this.avatarUrl,
    this.bio,
    this.followerCount,
    this.niches = const <String>[],
    this.hasExistingPartnership = false,
  });

  final String creatorAccountId;
  final String? displayName;
  final String? handle;
  final String? avatarUrl;
  final String? bio;
  final int? followerCount;
  final List<String> niches;
  final bool hasExistingPartnership;

  /// Best available label: display name → @handle → short id fallback.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final h = handle?.trim();
    if (h != null && h.isNotEmpty) return '@$h';
    return creatorAccountId.length >= 8
        ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
        : 'Creator';
  }

  CreatorInvite copyWith({
    String? creatorAccountId,
    String? displayName,
    String? handle,
    String? avatarUrl,
    String? bio,
    int? followerCount,
    List<String>? niches,
    bool? hasExistingPartnership,
  }) {
    return CreatorInvite(
      creatorAccountId: creatorAccountId ?? this.creatorAccountId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followerCount: followerCount ?? this.followerCount,
      niches: niches ?? this.niches,
      hasExistingPartnership:
          hasExistingPartnership ?? this.hasExistingPartnership,
    );
  }
}

/// Skill §2 + §11 — 5-state machine. `Invited` → `Active`/`Declined`
/// (terminal); `Active` ⇄ `Paused`; `Active`/`Paused` → `Ended` (terminal).
enum PartnershipState { invited, declined, active, paused, ended }

/// Mirrors `PartnershipDto` from `GET /v1/vendor/partnerships`. The backend
/// does not publish creator display name/handle/avatar on this resource —
/// only `creatorProfileId` — so screens can only show a short id fallback
/// unless a separate creator lookup is added (see [CreatorInvite.label] for
/// the same fallback pattern used by the invite picker).
class VendorPartnership {
  const VendorPartnership({
    required this.id,
    required this.vendorProfileId,
    required this.creatorProfileId,
    required this.state,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.invitedAt,
    this.respondedAt,
    this.endedAt,
    this.endReason,
    this.brandBriefId,
    required this.initiatedByCreator,
    this.requestMessage,
    this.vendorRating,
  });

  final String id;
  final String vendorProfileId;
  final String creatorProfileId;
  final PartnershipState state;

  /// Fractions (0..1), not whole percents.
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final DateTime? endedAt;
  final String? endReason;
  final String? brandBriefId;
  final bool initiatedByCreator;
  final String? requestMessage;
  final double? vendorRating;

  /// Best available label until the backend exposes creator display fields.
  String get creatorLabel => creatorProfileId.length >= 8
      ? 'Creator ••${creatorProfileId.substring(creatorProfileId.length - 4)}'
      : 'Creator';
}
