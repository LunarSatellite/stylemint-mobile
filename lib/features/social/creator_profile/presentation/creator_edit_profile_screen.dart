import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class CreatorEditProfileScreen extends ConsumerStatefulWidget {
  const CreatorEditProfileScreen({
    this.initialDisplayName = '',
    this.initialHandle = '',
    super.key,
  });

  final String initialDisplayName;
  final String initialHandle;

  @override
  ConsumerState<CreatorEditProfileScreen> createState() =>
      _CreatorEditProfileScreenState();
}

class _CreatorEditProfileScreenState
    extends ConsumerState<CreatorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _bioCtrl;

  late List<String> _tags;
  String _originalBio = '';

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _tags = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seedFromProvider();
  }

  void _seedFromProvider() {
    final data = ref.read(creatorProfileEditProvider);
    if (_nicknameCtrl.text.isEmpty) {
      _nicknameCtrl.text = widget.initialDisplayName.isNotEmpty
          ? widget.initialDisplayName
          : data.displayName;
    }
    if (_bioCtrl.text.isEmpty && data.bio.isNotEmpty) {
      _bioCtrl.text = data.bio;
      _originalBio = data.bio;
    }
    if (_tags.isEmpty && data.tags.isNotEmpty) {
      _tags = List<String>.from(data.tags);
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedBio = _bioCtrl.text.trim();
    final bioChanged = trimmedBio != _originalBio;

    ref.read(creatorProfileEditProvider.notifier).update(
      displayName: _nicknameCtrl.text.trim(),
      bio: bioChanged ? trimmedBio : _originalBio,
      tags: List<String>.from(_tags),
      niches: ref.read(creatorProfileEditProvider).niches,
    );

    final accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (accountId == null || accountId.isEmpty) return;

    final rowVersion = ref
        .read(creatorProfileNotifierProvider(accountId))
        .maybeWhen(loadSuccess: (p) => p.rowVersion, orElse: () => '');

    await ref.read(updateCreatorProfileNotifierProvider.notifier).submit(
      accountId: accountId,
      rowVersion: rowVersion,
      displayName: _nicknameCtrl.text.trim(),
      bio: bioChanged ? trimmedBio : null,
      tags: List<String>.from(_tags),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<UpdateCreatorProfileState>(
        updateCreatorProfileNotifierProvider,
        (_, next) {
          next.maybeWhen(
            success: (_) {
              final id = ref.read(sessionControllerProvider).maybeWhen(
                authenticated: (id) => id,
                orElse: () => null,
              );
              if (id != null) {
                unawaited(
                  ref
                      .read(creatorProfileNotifierProvider(id).notifier)
                      .load(),
                );
              }
              if (mounted) context.pop();
            },
            failure: (f) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(NetworkExceptions.getMessage(f))),
                );
              }
            },
            orElse: () {},
          );
        },
      )
      ..listen<CreatorProfileEditData>(
        creatorProfileEditProvider,
        (_, data) {
          if (!mounted) return;
          if (_nicknameCtrl.text.isEmpty && data.displayName.isNotEmpty) {
            _nicknameCtrl.text = data.displayName;
          }
          if (_bioCtrl.text.isEmpty && data.bio.isNotEmpty) {
            _bioCtrl.text = data.bio;
            _originalBio = data.bio;
          }
          if (_tags.isEmpty && data.tags.isNotEmpty) {
            // Defer setState to avoid calling it during the current build frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tags = List<String>.from(data.tags));
            });
          }
        },
      );

    final bool isSubmitting = ref
        .watch(updateCreatorProfileNotifierProvider)
        .maybeWhen<bool>(submitting: () => true, orElse: () => false);

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
          'Edit Profile Details',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => unawaited(_save()),
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16, vertical: DesignTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nickname ───────────────────────────────────────────────────
              _SectionLabel('Nickname'),
              const SizedBox(height: DesignTokens.s8),
              TextFormField(
                controller: _nicknameCtrl,
                style: _inputStyle,
                textInputAction: TextInputAction.next,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g. Danny Perierra',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Bio ────────────────────────────────────────────────────────
              _SectionLabel('Profile Bio'),
              const SizedBox(height: DesignTokens.s8),
              TextFormField(
                controller: _bioCtrl,
                style: _inputStyle,
                maxLines: 4,
                maxLength: 300,
                textInputAction: TextInputAction.newline,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$currentLength / $maxLength',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                decoration: DesignTokens.inputDecoration(
                  labelText: 'About Me',
                  hintText: 'Tell your audience about yourself...',
                ),
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Profile Tags ───────────────────────────────────────────────
              _SectionLabel('Profile Tags'),
              const SizedBox(height: DesignTokens.s4),
              const Text(
                'Tags appear on your profile as achievement chips.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              _TagsRow(
                tags: _tags,
                onTap: () async {
                  final result = await context.push<List<String>>(
                    RouteNames.creatorProfileTags,
                    extra: List<String>.from(_tags),
                  );
                  if (result != null) setState(() => _tags = result);
                },
              ),
              const SizedBox(height: DesignTokens.s32),

              // ── Save button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => unawaited(_save()),
                  style: DesignTokens.primaryButtonStyle(),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: DesignTokens.s32),
            ],
          ),
        ),
      ),
    );
  }

  static const _inputStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    color: DesignTokens.textWhite,
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      );
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags, required this.onTap});
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = tags.isEmpty
        ? 'No tags added'
        : tags.take(3).join(', ') + (tags.length > 3 ? '…' : '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tags.isEmpty ? 'Add tags' : '${tags.length} tag${tags.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textMuted),
          ],
        ),
      ),
    );
  }
}
