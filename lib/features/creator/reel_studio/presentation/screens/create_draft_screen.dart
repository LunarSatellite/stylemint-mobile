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

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDraftNotifierProvider);

    ref.listen<CreateDraftState>(createDraftNotifierProvider, (_, next) {
      next.maybeWhen(
        saved: (_) => context.pop(),
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
        title: const Text('Create Draft', style: DesignTokens.titleMedium),
        actions: [
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
            padding: const EdgeInsets.all(DesignTokens.s16),
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
                const CoachingScoreCard(
                  overallScore: 0.75,
                  areas: [
                    FeedbackArea(label: 'Caption', score: 0.8),
                    FeedbackArea(label: 'Hashtags', score: 0.65),
                    FeedbackArea(label: 'Engagement', score: 0.72),
                    FeedbackArea(label: 'Timing', score: 0.85),
                  ],
                  suggestions: [
                    'Add 2-3 trending hashtags',
                    'Make caption shorter for higher retention',
                  ],
                ),
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
}
