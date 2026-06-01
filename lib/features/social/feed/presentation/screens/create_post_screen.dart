import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isPosting = false;
  String? _errorText;
  final List<String> _imagePaths = [];
  final List<String> _taggedProductIds = [];

  bool get _canPost => _contentController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() {
      _isPosting = true;
      _errorText = null;
    });

    final result = await ref.read(feedNotifierProvider.notifier).createPost(
      content: _contentController.text.trim(),
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
      taggedProductIds: _taggedProductIds.isEmpty ? null : _taggedProductIds,
    );

    setState(() => _isPosting = false);

    result.maybeWhen(
      postSuccess: (post) {
        if (mounted) Navigator.of(context).pop();
      },
      postFailure: (failure) {
        setState(() => _errorText = 'Failed to create post. Try again.');
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Create Post', style: DesignTokens.titleLarge),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                style: DesignTokens.bodyText,
                decoration: DesignTokens.inputDecoration(
                  hintText: "What's on your mind?",
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s8),
                    itemBuilder: (_, i) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(DesignTokens.s8),
                      ),
                      child: const Icon(Icons.image, color: DesignTokens.iconLight),
                    ),
                  ),
                ),
              const SizedBox(height: DesignTokens.s16),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                  child: Text(
                    _errorText!,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),
              ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: _canPost && !_isPosting ? _submit : null,
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.buttonPrimaryText,
                        ),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
