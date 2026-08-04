import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorApplyStep3ReviewScreen extends ConsumerStatefulWidget {
  const CreatorApplyStep3ReviewScreen({super.key, this.onEditStep});

  final ValueChanged<int>? onEditStep;

  @override
  ConsumerState<CreatorApplyStep3ReviewScreen> createState() =>
      CreatorApplyStep3ReviewScreenState();
}

class CreatorApplyStep3ReviewScreenState
    extends ConsumerState<CreatorApplyStep3ReviewScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<CreatorFormData>(creatorFormProvider, (_, __) {
      ref.read(stepCanProceedProvider.notifier).state = canSubmit;
    });
  }

  bool get canSubmit {
    final data = ref.read(creatorFormProvider);
    return data.categoryIds.isNotEmpty && data.platforms.isNotEmpty;
  }

  Future<void> submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    ref.read(stepCanProceedProvider.notifier).state = false;
    final data = ref.read(creatorFormProvider);

    final form = CreatorApplicationForm(
      fullName: data.fullName,
      handle: '',
      platforms: data.platforms,
      contentCategoryIds: data.categoryIds.toList(),
      audienceBand: data.audienceBand,
      bio: data.whyJoin,
    );

    await ref.read(creatorApplyNotifierProvider.notifier).submit(form);
    if (!mounted) return;
    setState(() => _submitting = false);
    ref.read(stepCanProceedProvider.notifier).state = canSubmit;

    final state = ref.read(creatorApplyNotifierProvider);
    state.maybeWhen(
      loadSuccess: (application) {
        ref.read(creatorFormProvider.notifier).reset();
        _routeAfterSubmit(application.status);
      },
      loadFailure: (failure) {
        SmSnackbar.error(
          context,
          'Couldn\'t submit your application. Please try again.',
        );
      },
      orElse: () {},
    );
  }

  void _routeAfterSubmit(CreatorApplicationStatus status) {
    final route = switch (status) {
      CreatorApplicationStatus.pending => RouteNames.creatorApplySubmitted,
      CreatorApplicationStatus.underReview =>
        RouteNames.creatorApplyUnderReview,
      CreatorApplicationStatus.approved => RouteNames.creatorApplyApproved,
      CreatorApplicationStatus.rejected => RouteNames.creatorApplyRejected,
    };
    context.go(route);
  }

  void _editStep(int step) {
    widget.onEditStep?.call(step);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(creatorFormProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            border: Border.all(color: DesignTokens.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review Your Application',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Review the details you entered before you submit your '
                'application.',
                style: DesignTokens.smallDescription,
              ),
              const SizedBox(height: DesignTokens.s8),
              const Divider(
                height: 1,
                thickness: 1,
                color: DesignTokens.borderDefault,
              ),
              const SizedBox(height: DesignTokens.s4),
              _SectionBlock(
                title: 'Personal Information',
                onEdit: () => _editStep(0),
                rows: _personalRows(data),
              ),
              const SizedBox(height: DesignTokens.s16),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.s8),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: DesignTokens.borderDefault,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              _SectionBlock(
                title: 'Social Media Profile',
                onEdit: () => _editStep(1),
                rows: _socialRows(data),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_Row> _personalRows(CreatorFormData data) => [
    if (data.fullName.isNotEmpty) _Row('Full Name', data.fullName),
    if (data.email.isNotEmpty) _Row('Email Address', data.email),
    if (data.phone.isNotEmpty) _Row('Phone Number', data.phone),
    if (data.country.isNotEmpty) _Row('Country/Region', data.country),
    if (data.categories.isNotEmpty)
      _Row('Content Categories', data.categories.join(', '), chips: true),
    if (data.whyJoin.isNotEmpty)
      _Row('Why do you want to join ReelCommerce?', data.whyJoin, wrap: true),
  ];

  List<_Row> _socialRows(CreatorFormData data) {
    final rows = <_Row>[];
    if (data.platforms.isEmpty) {
      rows.add(const _Row('Connected profiles', 'None', muted: true));
    } else {
      for (final p in data.platforms) {
        rows.add(_Row(p.name, '@${p.handle}'));
      }
    }
    final apiTotal = data.platforms.fold<int>(
      0,
      (sum, p) => sum + p.followerCount,
    );
    if (data.platforms.isNotEmpty) {
      rows.add(_Row('Total Followers/Subscribers', _formatFollowers(apiTotal)));
      final breakdown = data.platforms
          .where((p) => p.followerCount > 0)
          .map((p) => '{p.name} {_formatFollowers(p.followerCount)}')
          .join('  \u00b7  ');
      if (breakdown.isNotEmpty) {
        rows.add(
          _Row('Per platform', breakdown, muted: true, showLabel: false),
        );
      }
    } else {
      rows.add(
        const _Row(
          'Total Followers/Subscribers',
          'Not provided',
          muted: true,
        ),
      );
    }

    if (data.engagementRate.isNotEmpty) {
      final engagement = kEngagementRates
          .firstWhere(
            (e) => e.value == data.engagementRate,
            orElse: () => const EngagementRateOption('', ''),
          )
          .label;
      rows.add(
        _Row(
          'Average Engagement Rate',
          engagement.isEmpty ? data.engagementRate : engagement,
        ),
      );
    } else {
      rows.add(
        const _Row(
          'Average Engagement Rate',
          'Not provided',
          muted: true,
        ),
      );
    }
    if (data.contentKinds.isNotEmpty) {
      final labels = data.contentKinds
          .map(
            (id) => kContentKinds
                .firstWhere(
                  (k) => k.id == id,
                  orElse: () => ContentKindOption(id, id),
                )
                .label,
          )
          .join(', ');
      rows.add(_Row('Content Type', labels, chips: true));
    } else {
      rows.add(const _Row('Content Type', 'Not provided', muted: true));
    }
    if (data.sampleUrls.isEmpty) {
      rows.add(const _Row('Sample Content', 'Not provided', muted: true));
    } else {
      for (var i = 0; i < data.sampleUrls.length; i++) {
        rows.add(
          _Row('Sample Content ${i + 1}', data.sampleUrls[i], wrap: true),
        );
      }
    }
    return rows;
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final VoidCallback onEdit;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: DesignTokens.sectionInnerTitle),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: DesignTokens.primaryGreen,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: DesignTokens.s4),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.value, {
    this.wrap = false,
    this.muted = false,
    this.showLabel = true,
    this.chips = false,
  });

  final String label;
  final String value;
  final bool wrap;
  final bool muted;
  final bool showLabel;
  final bool chips;

  @override
  Widget build(BuildContext context) {
    if (chips) {
      final items = value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel)
              Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
            if (showLabel) const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final item in items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s12,
                      vertical: DesignTokens.s8,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.chipRadius,
                      ),
                      border: Border.all(color: DesignTokens.borderDefault),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          if (showLabel) const SizedBox(height: DesignTokens.s4),
          Text(
            value,
            maxLines: wrap ? null : 2,
            overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: muted ? DesignTokens.textMuted : DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatFollowers(int n) {
  if (n <= 0) return '0';
  return n.toString();
}
