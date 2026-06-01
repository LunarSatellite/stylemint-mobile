import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/widgets/platform_connector_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  static const _categories = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Tech',
    'Food',
    'Travel',
    'Art',
    'Music',
    'Gaming',
    'Photography',
    'Dance',
  ];

  static const List<Map<String, dynamic>> _platforms = [
    {'name': 'Instagram', 'icon': Icons.camera_alt_outlined, 'id': 'instagram'},
    {'name': 'TikTok', 'icon': Icons.music_note_outlined, 'id': 'tiktok'},
    {'name': 'YouTube', 'icon': Icons.play_circle_outline, 'id': 'youtube'},
    {'name': 'Snapchat', 'icon': Icons.face_outlined, 'id': 'snapchat'},
    {'name': 'X (Twitter)', 'icon': Icons.alternate_email, 'id': 'x'},
  ];

  final _fullNameController = TextEditingController();
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();
  final _portfolioUrlController = TextEditingController();

  final _platformHandleControllers = <String, TextEditingController>{};
  final _platformFollowerControllers = <String, TextEditingController>{};

  final _selectedCategories = <String>{};
  List<String> _selectedPlatformIds = [];
  String? _identityDocUrl;
  bool _isSubmitting = false;

  bool _hasCheckedStatus = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkStatus);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _portfolioUrlController.dispose();
    for (final c in _platformHandleControllers.values) {
      c.dispose();
    }
    for (final c in _platformFollowerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkStatus() {
    if (_hasCheckedStatus) return;
    _hasCheckedStatus = true;
    ref.read(creatorApplyNotifierProvider.notifier).checkStatus();
  }

  void _addPlatform(String id) {
    if (_selectedPlatformIds.contains(id)) return;
    setState(() {
      _selectedPlatformIds = [..._selectedPlatformIds, id];
    });
    _platformHandleControllers[id] ??= TextEditingController();
    _platformFollowerControllers[id] ??= TextEditingController();
  }

  void _removePlatform(String id) {
    setState(() {
      _selectedPlatformIds =
          _selectedPlatformIds.where((p) => p != id).toList();
    });
    _platformHandleControllers.remove(id)?.dispose();
    _platformFollowerControllers.remove(id)?.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final fullName = _fullNameController.text.trim();
    final handle = _handleController.text.trim();
    final bio = _bioController.text.trim();
    final portfolioUrl = _portfolioUrlController.text.trim();

    if (fullName.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (handle.isEmpty) {
      _showError('Please enter your handle.');
      return;
    }
    if (_selectedPlatformIds.isEmpty) {
      _showError('Please connect at least one platform.');
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showError('Please select at least one category.');
      return;
    }
    if (bio.isEmpty) {
      _showError('Please write a short bio.');
      return;
    }

    final platforms = _selectedPlatformIds
        .map((id) {
          final platformDef =
              _platforms.firstWhere((p) => p['id'] == id);
          return Platform(
            id: id,
            name: platformDef['name'] as String,
            handle: _platformHandleControllers[id]?.text.trim() ?? '',
            followerCount: int.tryParse(
                  _platformFollowerControllers[id]?.text.trim() ?? '0',
                ) ??
                0,
            connected: false,
          );
        })
        .toList(growable: false);

    final form = CreatorApplicationForm(
      fullName: fullName,
      handle: handle,
      platforms: platforms,
      categories: _selectedCategories.toList(growable: false),
      bio: bio,
      portfolioUrl: portfolioUrl.isNotEmpty ? portfolioUrl : null,
      identityDocUrl: _identityDocUrl,
    );

    setState(() => _isSubmitting = true);
    await ref.read(creatorApplyNotifierProvider.notifier).submit(form);
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorApplyNotifierProvider);

    ref.listen(creatorApplyNotifierProvider, (prev, next) {
      next.whenOrNull(
        loadSuccess: (app) {
          if (app.status == CreatorApplicationStatus.approved) {
            context.go(RouteNames.creatorDash);
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: Text('Creator Application', style: DesignTokens.oneLinerSemibold),
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
      ),
      body: SafeArea(
        child: state.when(
          initial: () => _buildForm(),
          loadInProgress: _loader,
          loadSuccess: _buildStatusOrForm,
          loadFailure: (failure) => SmErrorView(
            message: 'Could not load application status.',
            onRetry: () {
              _hasCheckedStatus = false;
              _checkStatus();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOrForm(CreatorApplication application) {
    switch (application.status) {
      case CreatorApplicationStatus.pending:
      case CreatorApplicationStatus.underReview:
        return _ApplicationStatusCard(application: application);
      case CreatorApplicationStatus.rejected:
        return _buildForm();
      case CreatorApplicationStatus.approved:
        Future.microtask(() {
          if (context.mounted) context.go(RouteNames.creatorDash);
        });
        return _loader();
    }
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself', style: DesignTokens.titleLarge),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Fill in the details below to apply as a creator on Style Mint.',
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Full Name ---
          TextField(
            controller: _fullNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Handle ---
          TextField(
            controller: _handleController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Handle / Username',
              hintText: '@yourhandle',
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Platforms ---
          Text('Connect Platforms', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Link your social accounts to verify your reach.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s12),

          ..._selectedPlatformIds.map((id) {
            final platformDef =
                _platforms.firstWhere((p) => p['id'] == id);
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: PlatformConnectorTile(
                platformName: platformDef['name'] as String,
                platformIcon: platformDef['icon'] as IconData,
                handleController: _platformHandleControllers[id]!,
                followerCountController: _platformFollowerControllers[id]!,
                connected: false,
                onRemove: () => _removePlatform(id),
              ),
            );
          }),

          if (_selectedPlatformIds.length < _platforms.length)
            _AddPlatformButton(
              platforms: _platforms
                  .where(
                    (p) => !_selectedPlatformIds.contains(p['id']),
                  )
                  .toList(),
              onSelected: _addPlatform,
            ),

          const SizedBox(height: DesignTokens.s24),

          // --- Categories ---
          Text('Content Categories', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Select categories that match your content.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: _categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: () => _toggleCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s8,
                  ),
                  decoration: isSelected
                      ? DesignTokens.chipDecorationSelected()
                      : DesignTokens.chipDecorationDefault(),
                  child: Text(
                    category,
                    style: (isSelected
                            ? DesignTokens.mediumSemibold
                            : DesignTokens.mediumRegular)
                        .copyWith(
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.chipsDefaultText,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Bio ---
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Bio',
              hintText: 'Tell brands about your content style...',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Portfolio URL ---
          TextField(
            controller: _portfolioUrlController,
            keyboardType: TextInputType.url,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Portfolio URL (optional)',
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- ID Upload ---
          _IdUploadTile(
            docUrl: _identityDocUrl,
            onUpload: () => _uploadIdentityDoc(),
            onRemove: () => setState(() => _identityDocUrl = null),
          ),
          const SizedBox(height: DesignTokens.s28),

          // --- Submit ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: DesignTokens.primaryButtonStyle(),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  : Text(
                      'Submit Application',
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    );
  }

  Future<void> _uploadIdentityDoc() async {
    // Placeholder — real implementation would use image_picker
    //
    // final result = await ref
    //     .read(creatorRepositoryProvider)
    //     .uploadIdentityDoc(filePath);
    // result.fold(
    //   (f) => _showError('Upload failed.'),
    //   (url) => setState(() => _identityDocUrl = url),
    // );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _AddPlatformButton extends StatelessWidget {
  const _AddPlatformButton({
    required this.platforms,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> platforms;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: DesignTokens.bgAppBody,
      itemBuilder: (_) => platforms.map((p) {
        return PopupMenuItem<String>(
          value: p['id'] as String,
          child: Row(
            children: [
              Icon(p['icon'] as IconData, color: DesignTokens.textWhite, size: 20),
              const SizedBox(width: DesignTokens.s12),
              Text(
                p['name'] as String,
                style: DesignTokens.oneLinerRegular,
              ),
            ],
          ),
        );
      }).toList(growable: false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          border: Border.all(
            color: DesignTokens.borderDefault,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: DesignTokens.textMuted, size: 20),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Add Platform',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdUploadTile extends StatelessWidget {
  const _IdUploadTile({
    required this.docUrl,
    required this.onUpload,
    required this.onRemove,
  });

  final String? docUrl;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: docUrl != null ? onRemove : onUpload,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          border: Border.all(
            color: docUrl != null
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                docUrl != null ? Icons.check_circle : Icons.upload_file,
                color: docUrl != null
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docUrl != null
                        ? 'ID Document Uploaded'
                        : 'Upload ID Document',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    docUrl != null ? 'Tap to remove' : 'Passport or citizenship',
                    style: DesignTokens.smallRegular,
                  ),
                ],
              ),
            ),
            Icon(
              docUrl != null ? Icons.close : Icons.chevron_right,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  const _ApplicationStatusCard({required this.application});

  final CreatorApplication application;

  @override
  Widget build(BuildContext context) {
    final isPending = application.status == CreatorApplicationStatus.pending;
    final statusColor = isPending
        ? DesignTokens.secondaryYellow
        : DesignTokens.colorInfo;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s24),
            decoration: DesignTokens.cardDecoration(
              borderColor: statusColor.withOpacity(0.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending ? Icons.hourglass_top : Icons.rate_review_outlined,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Text(
                  application.status.label,
                  style: DesignTokens.titleMedium.copyWith(color: statusColor),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  isPending
                      ? 'Your application has been received and is awaiting review. We\'ll notify you once there\'s an update.'
                      : 'Your application is being reviewed by our team. This usually takes 1-2 business days.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.bodyText,
                ),
                if (application.status == CreatorApplicationStatus.rejected &&
                    application.rejectionReason != null) ...[
                  const SizedBox(height: DesignTokens.s16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.s12),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorError.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                    ),
                    child: Text(
                      application.rejectionReason!,
                      style: DesignTokens.mediumRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
