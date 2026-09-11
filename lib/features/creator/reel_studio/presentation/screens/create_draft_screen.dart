import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/notifiers/reel_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/widgets/coaching_score_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/widgets/hashtag_input.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreateDraftScreen extends ConsumerStatefulWidget {
  const CreateDraftScreen({super.key});

  @override
  ConsumerState<CreateDraftScreen> createState() => _CreateDraftScreenState();
}

class _CreateDraftScreenState extends ConsumerState<CreateDraftScreen> {
  final _captionController = TextEditingController();
  List<String> _hashtags = [];
  List<String> _taggedProductIds = [];
  SocialPlatform _platform = SocialPlatform.instagram;
  bool _isSaving = false;
  bool _isAnalyzing = false;
  bool _analysisFailed = false;
  CoachingFeedback? _coaching;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeDraft(String draftId) async {
    setState(() {
      _isAnalyzing = true;
      _analysisFailed = false;
    });
    final coaching = await ref
        .read(reelStudioNotifierProvider.notifier)
        .requestCoaching(draftId);
    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _coaching = coaching;
      _analysisFailed = coaching == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDraftNotifierProvider);
    final isEditing = ref
        .read(createDraftNotifierProvider.notifier)
        .isEditingExisting;

    ref.listen<CreateDraftState>(createDraftNotifierProvider, (_, next) {
      next.maybeWhen(
        saved: (draft) => unawaited(_analyzeDraft(draft.id)),
        saveFailure: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save draft')),
        ),
        orElse: () {},
      );
      _isSaving = next.maybeWhen(saving: () => true, orElse: () => false);
    });

    state.maybeWhen(
      editing: (caption, hashtags, taggedProductIds, platform) {
        _captionController.text = caption;
        _hashtags = hashtags;
        _taggedProductIds = taggedProductIds;
        _platform = platform;
      },
      orElse: () {},
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(
          isEditing ? 'Edit Draft' : 'Create Draft',
          style: DesignTokens.titleMedium,
        ),
        actions: [
          if (_coaching != null || _analysisFailed)
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Done',
                  style: TextStyle(color: DesignTokens.textLight)),
            ),
          TextButton(
            onPressed: _isSaving
                ? null
                : () =>
                    ref.read(createDraftNotifierProvider.notifier).save(),
            child: const Text('Save',
                style: TextStyle(color: DesignTokens.primaryGreen)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _captionController,
                  maxLines: 4,
                  style: DesignTokens.bodyText,
                  decoration: InputDecoration(
                    hintText: 'Write your caption...',
                    hintStyle: DesignTokens.bodyText.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                    filled: true,
                    fillColor: DesignTokens.bgAppBody,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.inputRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(createDraftNotifierProvider.notifier)
                      .setCaption(value),
                ),
                const SizedBox(height: DesignTokens.s16),
                HashtagInput(
                  initialHashtags: _hashtags,
                  onChanged: (hashtags) {
                    _hashtags = hashtags;
                    ref
                        .read(createDraftNotifierProvider.notifier)
                        .setHashtags(hashtags);
                  },
                ),
                const SizedBox(height: DesignTokens.s16),
                Text('Platform', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s8,
                  children: SocialPlatform.values.map((platform) {
                    final isSelected = platform == _platform;
                    return ChoiceChip(
                      label: Text(platform.displayName),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          _platform = platform;
                          ref
                              .read(createDraftNotifierProvider.notifier)
                              .setPlatform(platform);
                        }
                      },
                      selectedColor: DesignTokens.primaryGreen,
                      backgroundColor: DesignTokens.bgAppBody,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? DesignTokens.textDark
                            : DesignTokens.textLight,
                      ),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: DesignTokens.s24),
                _buildCoachingSection(),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: DesignTokens.baseBlack.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoachingSection() {
    if (_isAnalyzing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: DesignTokens.primaryGreen),
              SizedBox(height: DesignTokens.s8),
              Text('Analyzing your reel...', style: DesignTokens.bodyText),
            ],
          ),
        ),
      );
    }
    if (_coaching != null) {
      final coaching = _coaching!;
      return CoachingScoreCard(
        overallScore: coaching.overallScore,
        areas: coaching.areas,
        suggestions: coaching.suggestions,
      );
    }
    if (_analysisFailed) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.colorError.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Could not analyze this draft. Save again to retry.',
          style: DesignTokens.bodyText,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
