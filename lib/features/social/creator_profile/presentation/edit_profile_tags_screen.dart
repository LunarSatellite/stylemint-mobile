import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditProfileTagsScreen extends ConsumerStatefulWidget {
  const EditProfileTagsScreen({required this.initialTags, super.key});

  final List<String> initialTags;

  @override
  ConsumerState<EditProfileTagsScreen> createState() => _EditProfileTagsScreenState();
}

class _EditProfileTagsScreenState extends ConsumerState<EditProfileTagsScreen> {
  late List<String> _tags;
  final _tagInputCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _tagInputCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputCtrl.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagInputCtrl.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final accountId = ref.read(sessionControllerProvider).maybeWhen(
        authenticated: (id) => id,
        orElse: () => null,
      );
      if (accountId == null || accountId.isEmpty) {
        if (mounted) context.pop(List<String>.from(_tags));
        return;
      }
      final profileState = ref.read(creatorProfileNotifierProvider(accountId));
      CreatorProfile? profile = profileState.maybeWhen(
        loadSuccess: (p) => p,
        orElse: () => null,
      );
      if (profile == null) {
        // Profile not loaded yet - load it to get rowVersion.
        final result = await ref.read(creatorProfileNotifierProvider(accountId).notifier).load();
        profile = ref.read(creatorProfileNotifierProvider(accountId)).maybeWhen(
          loadSuccess: (p) => p,
          orElse: () => null,
        );
      }
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load profile')),
          );
          setState(() => _saving = false);
        }
        return;
      }
      final rowVersion = profile.rowVersion;
      // Backend requires displayName in the PATCH body. Prefer the edit
      // provider (always up to date in normal flow), but fall back to the
      // loaded profile if the edit provider was never seeded (e.g. opening
      // this screen directly without going through the edit profile route).
      final editData = ref.read(creatorProfileEditProvider);
      final displayName = editData.displayName.isNotEmpty
          ? editData.displayName
          : profile.displayName;
      await ref.read(updateCreatorProfileNotifierProvider.notifier).submit(
        accountId: accountId,
        rowVersion: rowVersion,
        displayName: displayName,
        tags: List<String>.from(_tags),
      );
      final state = ref.read(updateCreatorProfileNotifierProvider);
      state.whenOrNull(
        success: (_) {
          if (!mounted) return;
          // refresh profile so tags are reflected everywhere
          unawaited(ref.read(creatorProfileNotifierProvider(accountId).notifier).load());
          context.pop(List<String>.from(_tags));
        },
        failure: (f) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(NetworkExceptions.getMessage(f))),
          );
          setState(() => _saving = false);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile Tags',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Tags',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: DesignTokens.s8,
                      runSpacing: DesignTokens.s8,
                      children: _tags
                          .map((t) => _TagChip(
                                label: t,
                                onRemove: () => _removeTag(t),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: DesignTokens.s20),
                  TextField(
                    controller: _tagInputCtrl,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      color: DesignTokens.textWhite,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTag(),
                    decoration: DesignTokens.inputDecoration(
                      hintText: 'Add Tags',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add_rounded,
                          size: 18, color: DesignTokens.textWhite),
                      label: const Text(
                        'Add Tag',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.bgAppBody,
                        foregroundColor: DesignTokens.textWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(
                              color: DesignTokens.borderDefault),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              DesignTokens.textWhite),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: DesignTokens.s8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: DesignTokens.textMuted),
          ),
        ],
      ),
    );
  }
}
