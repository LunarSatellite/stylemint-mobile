import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_messaging_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

// ── Data ──────────────────────────────────────────────────────────────────────
//
// _Request is a display-only view-model adapted from the real
// PartnershipInvite/ActivePartnership domain entities (via
// partnershipsNotifierProvider) — no hardcoded brands/messages. category
// isn't returned by the partnerships API, so that field is left blank and
// the info row that shows it is skipped rather than fabricated. A products
// count is not returned either; it used to be carried as a hardcoded 0 and
// is now simply not modelled.

enum _Status { pending, accepted, declined }

class _Request {
  const _Request({
    required this.id,
    required this.vendorProfileId,
    this.vendorAccountId,
    required this.brandName,
    required this.rating,
    required this.timeAgo,
    required this.message,
    required this.commission,
    required this.category,
    required this.logoUrl,
    required this.status,
  });

  final String id;
  final String vendorProfileId;
  final String? vendorAccountId;
  final String brandName;

  /// The brand's rating, or **null** when it has none.
  ///
  /// This was a non-nullable `double` fed by `vendorRating ?? 0` on the
  /// invite path and by a literal `0` on the active path, and three cards
  /// drew it as "★ 0.0 Stars". Every brand without a rating — and every
  /// active partnership, unconditionally — was therefore published as a
  /// zero-star business. That is the same defect the brand trust score was
  /// retired for, on a different screen in the same feature: a null read as
  /// a zero.
  ///
  /// `vendorRating` is real where it is non-null (Catalog's weighted
  /// product-review rollup, joined onto the partnership DTO by
  /// `CatalogVendorRatingProvider`), so the figure stays — it just no
  /// longer has a stand-in. Null now means null, and [_BrandMeta] draws no
  /// star at all.
  final double? rating;
  final String timeAgo;
  final String message;
  final String commission;
  final String category;

  /// The brand's real logo, or empty when it has none. Both
  /// [PartnershipInvite] and [ActivePartnership] carry this from the server;
  /// this record used to drop it, so every brand fell back to a letter mark
  /// even when a logo existed.
  final String logoUrl;
  final _Status status;
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'just now';
}

/// Formats a commission for display.
///
/// [min] and [max] are **percents**, already scaled from the wire's fraction
/// by `commissionPercent` on the domain entity. This function used to be
/// handed the raw fraction: `0.15.toStringAsFixed(0)` is `"0"`, so a
/// partnership paying fifteen percent advertised itself as "0%".
String _commissionLabel(double min, double max) {
  final minStr = min.toStringAsFixed(min.truncateToDouble() == min ? 0 : 1);
  final maxStr = max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1);
  return min == max ? '$minStr%' : '$minStr-$maxStr%';
}

_Request _fromInvite(PartnershipInvite i) => _Request(
  id: i.id,
  vendorProfileId: i.vendorProfileId,
  vendorAccountId: i.vendorAccountId,
  brandName: i.vendorName,
  rating: i.vendorRating,
  timeAgo: _timeAgo(i.expiresAt),
  message: i.campaignBrief,
  commission: _commissionLabel(i.commissionPercent, i.commissionPercent),
  category: '',
  logoUrl: i.vendorLogoUrl,
  status: switch (i.status) {
    PartnershipStatus.declined => _Status.declined,
    _ => _Status.pending,
  },
);

_Request _fromActive(ActivePartnership a) => _Request(
  id: a.id,
  vendorProfileId: a.vendorProfileId,
  vendorAccountId: a.vendorAccountId,
  brandName: a.vendorName,
  // `ActivePartnership` carries no rating at all — `toActiveDomain()` never
  // set one — so there is nothing to show, not a zero to show.
  rating: null,
  timeAgo: _timeAgo(a.startedAt),
  message: '',
  commission: _commissionLabel(a.commissionPercent, a.commissionPercent),
  category: '',
  logoUrl: a.vendorLogoUrl,
  status: _Status.accepted,
);

// ── Screen ────────────────────────────────────────────────────────────────────

class PartnershipRequestsScreen extends ConsumerStatefulWidget {
  const PartnershipRequestsScreen({super.key});

  @override
  ConsumerState<PartnershipRequestsScreen> createState() =>
      _PartnershipRequestsScreenState();
}

class _PartnershipRequestsScreenState
    extends ConsumerState<PartnershipRequestsScreen> {
  int _tab = 0;

  _Request? _findInvite(String id) => ref
      .read(partnershipsNotifierProvider)
      .maybeWhen(
        loadSuccess: (invites, active, ended) =>
            invites.where((i) => i.id == id).map(_fromInvite).firstOrNull,
        orElse: () => null,
      );

  Future<void> _accept(String id) async {
    final req = _findInvite(id);
    if (req == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcceptSheet(
        request: req,
        onConfirm: () async {
          try {
            final ok = await ref
                .read(partnershipsNotifierProvider.notifier)
                .accept(id);
            if (!mounted) return;
            if (ok) {
              SmSnackbar.info(context, 'Partnership accepted!');
            } else {
              SmSnackbar.error(context, "Couldn't accept. Please try again.");
            }
          } catch (_) {
            if (mounted) {
              SmSnackbar.error(context, "Couldn't accept. Please try again.");
            }
          }
        },
      ),
    );
  }

  Future<void> _decline(String id) async {
    final req = _findInvite(id);
    if (req == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeclineSheet(
        request: req,
        onConfirm: () async {
          try {
            final ok = await ref
                .read(partnershipsNotifierProvider.notifier)
                .decline(id);
            if (!mounted) return;
            if (ok) {
              SmSnackbar.info(context, 'Partnership declined.');
            } else {
              SmSnackbar.error(context, "Couldn't decline. Please try again.");
            }
          } catch (_) {
            if (mounted) {
              SmSnackbar.error(context, "Couldn't decline. Please try again.");
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipsNotifierProvider);
    final items = state.maybeWhen(
      loadSuccess: (invites, active, ended) => [
        ...invites.map(_fromInvite),
        ...active.map(_fromActive),
      ],
      orElse: () => const <_Request>[],
    );
    final isLoading = state.maybeWhen(
      loadInProgress: () => true,
      orElse: () => false,
    );

    List<_Request> filtered(_Status s) =>
        items.where((r) => r.status == s).toList();

    final pending = filtered(_Status.pending).length;
    final accepted = filtered(_Status.accepted).length;
    final declined = filtered(_Status.declined).length;
    final currentList = [
      filtered(_Status.pending),
      filtered(_Status.accepted),
      filtered(_Status.declined),
    ][_tab];

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Partnership Requests',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: Column(
        children: [
          // Pill tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s4,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PillTab(
                    label: 'Pending ($pending)',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: _PillTab(
                    label: 'Accepted ($accepted)',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: _PillTab(
                    label: 'Declined ($declined)',
                    active: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: isLoading
                ? const SmPageLoader()
                : currentList.isEmpty
                ? Center(
                    child: Text(
                      'No ${['pending', 'accepted', 'declined'][_tab]} requests',
                      style: DesignTokens.mediumRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16,
                      0,
                      DesignTokens.s16,
                      DesignTokens.s24,
                    ),
                    itemCount: currentList.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.s12),
                    itemBuilder: (ctx, i) {
                      final req = currentList[i];
                      return _RequestCard(
                        request: req,
                        isPending: _tab == 0,
                        onAccept: () => _accept(req.id),
                        onDecline: () => _decline(req.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Pill tab ──────────────────────────────────────────────────────────────────

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? DesignTokens.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active
                ? DesignTokens.buttonPrimaryText
                : DesignTokens.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.request,
    required this.isPending,
    required this.onAccept,
    required this.onDecline,
  });

  final _Request request;
  final bool isPending;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;
  static const _previewLen = 100;

  bool get _isLong => widget.request.message.length > _previewLen;

  String get _displayMsg => _expanded || !_isLong
      ? widget.request.message
      : '${widget.request.message.substring(0, _previewLen)}...';

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandLogo(name: req.brandName, logoUrl: req.logoUrl),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.brandName,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _BrandMeta(rating: req.rating, trailing: req.timeAgo),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        final accountId =
                            (req.vendorAccountId != null &&
                                req.vendorAccountId!.isNotEmpty)
                            ? req.vendorAccountId
                            : null;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BrandMessagingScreen(
                              args: BrandMessagingArgs(
                                brandName: req.brandName,
                                category: req.category,
                                otherParticipantId: accountId,
                                profileId: accountId == null
                                    ? req.vendorProfileId
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Message Back',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: DesignTokens.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),

          // Message box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppFoundation,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _displayMsg,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                      if (_isLong)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Text(
                              _expanded ? ' Show less' : ' Read More',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Info rows
          _InfoRow(
            label: 'Proposed Commission',
            icon: Image.asset(
              'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
              width: 16,
              height: 16,
            ),
            trailing: _CommissionChip(req.commission),
          ),
          if (req.category.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            _InfoRow(
              label: 'Product Category',
              icon: Image.asset(
                'assets/images/creatordash/material-symbols_package-2-outline.png',
                width: 16,
                height: 16,
              ),
              trailingText: req.category,
            ),
          ],
          // A "Products" row stood here, fed by `ActivePartnership.productsCount`
          // — a hardcoded 0, so the row's `isNotEmpty` guard meant it never
          // actually drew. The count is recorded on the server
          // (Reels.TaggedProduct.PartnershipIdSnapshot) but no endpoint
          // returns it, so the field is gone rather than kept as a
          // permanent zero.

          // Action buttons (pending only)
          if (widget.isPending) ...[
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    filled: false,
                    onTap: widget.onDecline,
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    filled: true,
                    onTap: widget.onAccept,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Brand meta line (rating · trailing) ──────────────────────────────────────

/// The line under a brand's name on a request card.
///
/// Draws the star and the figure **only** when [rating] is non-null. It used
/// to be an inline `Row` repeated on three cards, each calling
/// `req.rating.toStringAsFixed(1)` on a non-nullable double that was `0`
/// whenever the brand had no rating — so all three published "★ 0.0 Stars"
/// about businesses nothing had ever rated. Absence is drawn as absence.
class _BrandMeta extends StatelessWidget {
  const _BrandMeta({required this.rating, required this.trailing});

  final double? rating;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final r = rating;
    final hasTrailing = trailing.isNotEmpty;
    if (r == null && !hasTrailing) return const SizedBox.shrink();

    final label = [
      if (r != null) '${r.toStringAsFixed(1)} Stars',
      if (hasTrailing) trailing,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Row(
          children: [
            if (r != null) ...[
              const Icon(
                Icons.star_rounded,
                size: 13,
                color: DesignTokens.secondaryYellow,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: r.toStringAsFixed(1),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' Stars',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasTrailing) ...[
              if (r != null) const SizedBox(width: 6),
              Flexible(
                child: Text(
                  r != null ? '· $trailing' : trailing,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Brand logo circle ─────────────────────────────────────────────────────────

/// The brand's own logo, falling back to its initial in a white circle.
///
/// This used to special-case two names: a brand whose name contained
/// "nike" was drawn as a bold '✓' and one containing "sephora" as a bold
/// 'S' — the app forging a brand mark for two companies StyleMint has no
/// relationship with, and substring-matched, so a Nepali vendor called
/// "Nikesh Traders" would have been given one too. There is no list of
/// brand marks to draw from and no business drawing one.
///
/// The real logo is now wired: both `PartnershipInvite` and
/// `ActivePartnership` carry `vendorLogoUrl` from the server, and `_Request`
/// passes it along. The letter is what a brand *without* a logo gets, and
/// what a logo that fails to load falls back to — never a mark this app
/// invented. A brand logo is not a product photo, so the photo guard has no
/// opinion here.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name, this.logoUrl = ''});

  final String name;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name.trim().isNotEmpty ? '$name logo' : 'Brand logo',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: logoUrl.trim().isEmpty
            ? _initial()
            : ClipOval(
                child: Image.network(
                  logoUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial(),
                ),
              ),
      ),
    );
  }

  Widget _initial() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.icon,
    this.trailing,
    this.trailingText,
  });

  final String label;
  final Widget? icon;
  final Widget? trailing;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        // `Spacer` plus an unbounded trailing overflowed this row by 133px
        // as soon as the commission chip held a real rate rather than the
        // "0%" it used to: a Spacer takes every remaining pixel first and
        // leaves the chip nothing to lay out in. Flexible on both sides
        // lets the label give way instead.
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: trailing ??
                (trailingText == null
                    ? const SizedBox.shrink()
                    : Text(
                        trailingText!,
                        textAlign: TextAlign.end,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
          ),
        ),
      ],
    );
  }
}

// ── Commission chip ───────────────────────────────────────────────────────────

class _CommissionChip extends StatelessWidget {
  const _CommissionChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label Commissions',
        style: DesignTokens.smallRegular.copyWith(
          color: const Color(0xFF0D1B4B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: DesignTokens.buttonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? DesignTokens.primaryGreen
              : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.black : DesignTokens.textWhite,
          ),
        ),
      ),
    );
  }
}

// ── Decline confirmation sheet ────────────────────────────────────────────────

const _kDeclineReasons = [
  'Not a good fit',
  'Commission too low',
  'Wrong category',
  'Already partnered',
  'Too busy',
  'Other',
];

class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet({required this.request, required this.onConfirm});

  final _Request request;
  final VoidCallback onConfirm;

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  String? _reason;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s24,
        DesignTokens.s16,
        DesignTokens.s24 + bottom,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: DesignTokens.s24),
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Info icon
          Image.asset(
            'assets/images/infoicon.png',
            width: 56,
            height: 56,
          ),
          const SizedBox(height: DesignTokens.s16),

          // Title
          const Text(
            'Confirm Decline',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Are you sure you want to decline this\nbrand collaboration request?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // Brand mini-card
          Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              children: [
                _BrandLogo(name: req.brandName, logoUrl: req.logoUrl),
                const SizedBox(width: DesignTokens.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.brandName,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _BrandMeta(rating: req.rating, trailing: req.category),
                    const SizedBox(height: DesignTokens.s8),
                    _CommissionChip(req.commission),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Reason dropdown
          DropdownButtonFormField<String>(
            initialValue: _reason,
            dropdownColor: DesignTokens.inputFieldFill,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DesignTokens.inputFieldDropdownIcon,
            ),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Reason (Optional)',
            ),
            items: _kDeclineReasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Confirmation message
          TextField(
            controller: _msgCtrl,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Confirmation Message',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // Decline button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                widget.onConfirm();
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
                child: const Text(
                  'Decline Partnership',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Accept confirmation sheet ─────────────────────────────────────────────────

class _AcceptSheet extends StatefulWidget {
  const _AcceptSheet({required this.request, required this.onConfirm});

  final _Request request;
  final VoidCallback onConfirm;

  @override
  State<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends State<_AcceptSheet> {
  DateTime? _startDate;
  bool _agreed = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.primaryGreen,
            onPrimary: DesignTokens.buttonPrimaryText,
            surface: DesignTokens.bgAppBody,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  String get _dateLabel => _startDate == null
      ? 'Expected Start Date'
      : '${_startDate!.day.toString().padLeft(2, '0')}/'
            '${_startDate!.month.toString().padLeft(2, '0')}/'
            '${_startDate!.year}';

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s24,
        DesignTokens.s16,
        DesignTokens.s24 + bottom,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: DesignTokens.s24),
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Info icon
          Image.asset('assets/images/infoicon.png', width: 56, height: 56),
          const SizedBox(height: DesignTokens.s16),

          // Title
          const Text(
            'Confirm Accept',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Are you sure you want to accept this\nbrand collaboration request?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // Brand mini-card
          Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              children: [
                _BrandLogo(name: req.brandName, logoUrl: req.logoUrl),
                const SizedBox(width: DesignTokens.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.brandName,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _BrandMeta(rating: req.rating, trailing: req.category),
                    const SizedBox(height: DesignTokens.s8),
                    _CommissionChip(req.commission),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Expected start date
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.inputFieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DesignTokens.inputFieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: _startDate == null
                            ? DesignTokens.inputFieldPlaceholder
                            : DesignTokens.inputFieldData,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: DesignTokens.inputFieldDropdownIcon,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Terms checkbox
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    side: const BorderSide(
                      color: DesignTokens.borderDefault,
                      width: 1.5,
                    ),
                    activeColor: DesignTokens.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Text(
                  'I agree to ',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
                Text(
                  'Partnership Terms',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // Accept button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: GestureDetector(
              onTap: () {
                if (!_agreed) {
                  SmSnackbar.error(
                    context,
                    'Please agree to the Partnership Terms.',
                  );
                  return;
                }
                Navigator.of(context).pop();
                widget.onConfirm();
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
                child: const Text(
                  'Accept Partnership',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
