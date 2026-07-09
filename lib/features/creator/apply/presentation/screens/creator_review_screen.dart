import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorReviewScreen extends ConsumerWidget {
  const CreatorReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(creatorFormProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s20,
          DesignTokens.s16, DesignTokens.s32,
        ),
        children: [
          const Text('Review Your Application',
              style: DesignTokens.titleMedium),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Please review your information before submitting your application.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s24),

          // Personal Information
          _ReviewCard(
            title: 'Personal Information',
            onEdit: () => context.go(RouteNames.creatorApply),
            children: [
              _ReviewRow(label: 'Full Name', value: data.fullName),
              _ReviewRow(label: 'Email', value: data.email),
              _ReviewRow(label: 'Phone', value: data.phone),
              _ReviewRow(label: 'Country', value: data.country),
              if (data.categories.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                const Text('Content Categories',
                    style: _ReviewCard._labelStyle),
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s6,
                  runSpacing: DesignTokens.s6,
                  children: data.categories
                      .map((c) => _SmallChip(label: c))
                      .toList(),
                ),
              ],
              if (data.whyJoin.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                const Text('Why Join', style: _ReviewCard._labelStyle),
                const SizedBox(height: DesignTokens.s4),
                Text(data.whyJoin, style: _ReviewCard._valueStyle),
              ],
            ],
          ),

          const SizedBox(height: DesignTokens.s16),

          // Social Media Profiles
          _ReviewCard(
            title: 'Social Media Profiles',
            onEdit: () => context.go(RouteNames.creatorApplySocial),
            children: [
              if (data.connectedPlatforms.isNotEmpty) ...[
                const Text('Connected Platforms',
                    style: _ReviewCard._labelStyle),
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s6,
                  runSpacing: DesignTokens.s6,
                  children: data.connectedPlatforms
                      .map((p) => _SmallChip(label: _platformLabel(p)))
                      .toList(),
                ),
                const SizedBox(height: DesignTokens.s12),
              ],
              if (data.totalFollowers.isNotEmpty)
                _ReviewRow(
                    label: 'Total Followers', value: data.totalFollowers),
              if (data.engagementRate.isNotEmpty)
                _ReviewRow(
                    label: 'Engagement Rate', value: data.engagementRate),
              if (data.contentTypes.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                const Text('Content Types', style: _ReviewCard._labelStyle),
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s6,
                  runSpacing: DesignTokens.s6,
                  children: data.contentTypes
                      .map((t) => _SmallChip(label: t))
                      .toList(),
                ),
              ],
              if (data.sampleUrls.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                const Text('Sample Content URLs',
                    style: _ReviewCard._labelStyle),
                const SizedBox(height: DesignTokens.s8),
                ...data.sampleUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s6),
                    child: Text(url, style: _ReviewCard._valueStyle),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        onPrevious: () => context.pop(),
        onSubmit: () => _submit(context, ref),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: DesignTokens.textWhite),
        onPressed: () => context.pop(),
      ),
      title: const Text('Creator Form', style: DesignTokens.oneLinerSemibold),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s12),
          child: _StepBar(currentStep: 2, totalSteps: 3),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final data = ref.read(creatorFormProvider);

    final categoryIds = data.categoryIds.toList();
    if (categoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one content category.'),
        ),
      );
      return;
    }

    final followers = _parseFollowers(data.totalFollowers);
    // Build the API payload from the collected wizard data. Fields the
    // /v1/creator/apply contract doesn't accept (email, phone, country,
    // engagement rate, content types, sample URLs) are intentionally not sent.
    final form = CreatorApplicationForm(
      fullName: data.fullName,
      handle: '',
      platforms: data.connectedPlatforms
          .map((id) => Platform(
                id: id,
                name: id,
                handle: '',
                followerCount: followers,
              ))
          .toList(),
      contentCategoryIds: categoryIds,
      audienceBand: _audienceBand(followers),
      bio: data.whyJoin,
    );

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
    ));

    await ref.read(creatorApplyNotifierProvider.notifier).submit(form);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss the progress spinner

    ref.read(creatorApplyNotifierProvider.notifier).submitState.maybeWhen(
          success: (_) {
            ref.read(creatorFormProvider.notifier).reset();
            context.go(RouteNames.creatorApplySubmitted);
          },
          failure: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Couldn’t submit your application. Please try again.',
                ),
              ),
            );
          },
          orElse: () {},
        );
  }

  /// Pulls a follower count out of the free-text field ("12,000" → 12000).
  int _parseFollowers(String raw) {
    final digits = raw.replaceAll(RegExp('[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Maps a self-reported follower count to the backend AudienceSizeBand (1..5).
  int _audienceBand(int followers) {
    if (followers >= 1000000) return 5; // 1M+
    if (followers >= 100000) return 4; // 100k–1M
    if (followers >= 10000) return 3; // 10k–100k
    if (followers >= 1000) return 2; // 1k–10k
    return 1; // <1k
  }

  String _platformLabel(String id) {
    switch (id) {
      case 'youtube':
        return 'YouTube';
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'tiktok':
        return 'TikTok';
      default:
        return id;
    }
  }
}

// ---------------------------------------------------------------------------
// Step bar — completed = green, current = white, future = dimmed
// ---------------------------------------------------------------------------
class _StepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        Color color;
        if (i < currentStep) {
          color = DesignTokens.primaryGreen;
        } else if (i == currentStep) {
          color = DesignTokens.textWhite;
        } else {
          color = DesignTokens.textWhite.withOpacity(0.25);
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Review card with title + edit button
// ---------------------------------------------------------------------------
class _ReviewCard extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  static const _labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    color: DesignTokens.textMuted,
    fontWeight: FontWeight.w400,
  );

  static const _valueStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    color: DesignTokens.textLight,
    fontWeight: FontWeight.w400,
  );

  const _ReviewCard({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: DesignTokens.sectionInnerTitle),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 14, color: DesignTokens.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.primaryGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s16),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single label/value row
// ---------------------------------------------------------------------------
class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _ReviewCard._labelStyle),
          const SizedBox(height: DesignTokens.s4),
          Text(value, style: _ReviewCard._valueStyle),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small display chip (read-only, always green-tinted)
// ---------------------------------------------------------------------------
class _SmallChip extends StatelessWidget {
  final String label;
  const _SmallChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12, vertical: DesignTokens.s6),
      decoration: BoxDecoration(
        color: DesignTokens.chipsSelectedFill,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.chipsSelectedBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar: Previous + Submit
// ---------------------------------------------------------------------------
class _SubmitBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;
  const _SubmitBar({required this.onPrevious, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _Pill(
                label: 'Previous',
                prefixIcon: Icons.arrow_back_rounded,
                fill: DesignTokens.buttonGrayFill,
                textColor: DesignTokens.textWhite,
                onTap: onPrevious,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _Pill(
                label: 'Submit',
                suffixIcon: Icons.check_rounded,
                fill: DesignTokens.primaryGreen,
                textColor: DesignTokens.buttonPrimaryText,
                onTap: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color fill;
  final Color textColor;
  final VoidCallback? onTap;
  const _Pill({
    required this.label,
    required this.fill,
    required this.textColor,
    required this.onTap,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: DesignTokens.iconSmall, color: textColor),
                const SizedBox(width: DesignTokens.s6),
              ],
              Text(label,
                  style:
                      DesignTokens.oneLinerSemibold.copyWith(color: textColor)),
              if (suffixIcon != null) ...[
                const SizedBox(width: DesignTokens.s6),
                Icon(suffixIcon,
                    size: DesignTokens.iconSmall, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
