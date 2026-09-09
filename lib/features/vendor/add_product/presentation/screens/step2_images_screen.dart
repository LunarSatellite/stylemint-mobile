import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step2ImagesScreen extends ConsumerStatefulWidget {
  const Step2ImagesScreen({super.key});

  @override
  ConsumerState<Step2ImagesScreen> createState() => _Step2ImagesScreenState();
}

class _Step2ImagesScreenState extends ConsumerState<Step2ImagesScreen> {
  final List<String> _images = [];
  int _primaryIndex = 0;
  ProductVideoInfo? _video;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addProductNotifierProvider)
          .maybeWhen(
            loadSuccess: (fs) {
              if (fs.step2 != null) {
                setState(() {
                  _images.addAll(fs.step2!.images);
                  _primaryIndex = fs.step2!.primaryImageIndex;
                  _video = fs.step2!.video;
                });
              }
            },
            orElse: () {},
          );
    });
  }

  void _syncFromState(AddProductState state) {
    state.maybeWhen(
      loadSuccess: (fs) {
        if (fs.step2 != null) {
          setState(() {
            _images
              ..clear()
              ..addAll(fs.step2!.images);
            _primaryIndex = fs.step2!.primaryImageIndex;
            _video = fs.step2!.video;
            _uploading = false;
          });
        }
      },
      loadFailure: (_, e) {
        setState(() => _uploading = false);
      },
      orElse: () {},
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    await ref
        .read(addProductNotifierProvider.notifier)
        .uploadImage(picked.path);
  }

  void _removeImage(int index) {
    if (index < _primaryIndex) {
      _primaryIndex--;
    } else if (index == _primaryIndex && _images.length > 1) {
      _primaryIndex = 0;
    }
    setState(() => _images.removeAt(index));
    _emitUpdate();
  }

  void _setPrimary(int index) {
    setState(() => _primaryIndex = index);
    _emitUpdate();
  }

  void _emitUpdate() {
    ref
        .read(addProductNotifierProvider.notifier)
        .updateImages(
          ImagesInfo(
            images: List.from(_images),
            primaryImageIndex: _primaryIndex,
            video: _video,
          ),
        );
  }

  Future<void> _editVideo() async {
    final urlController = TextEditingController(text: _video?.cdnUrl ?? '');
    final durationController = TextEditingController(
      text: _video?.durationSeconds.toString() ?? '',
    );
    final updated = await showDialog<ProductVideoInfo>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Add product video link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'HTTPS video URL',
                hintText: 'https://cdn.example.com/video.mp4',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration in seconds (1–60)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              final duration = int.tryParse(durationController.text);
              final parsedUrl = Uri.tryParse(url);
              if (parsedUrl == null ||
                  !parsedUrl.hasScheme ||
                  !parsedUrl.hasAuthority ||
                  duration == null ||
                  duration < 1 ||
                  duration > 60) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid video URL and a duration from 1 to 60 seconds.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                ProductVideoInfo(cdnUrl: url, durationSeconds: duration),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    urlController.dispose();
    durationController.dispose();
    if (updated == null || !mounted) return;
    setState(() => _video = updated);
    _emitUpdate();
  }

  void _removeVideo() {
    setState(() => _video = null);
    _emitUpdate();
  }

  void _onProceed() {
    _emitUpdate();
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddProductState>(addProductNotifierProvider, (_, next) {
      _syncFromState(next);
    });

    final notifier = ref.read(addProductNotifierProvider.notifier);
    final canProceed =
        _images.length >= ImagesInfo.minImages &&
        _images.length <= ImagesInfo.maxImages;
    final remaining = ImagesInfo.minImages - _images.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Images & Media',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  const Text(
                    'Upload 5 - 10 images (max 5mb each in JPG/PNG)',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    remaining > 0
                        ? "$_images.length/${ProductFormState.maxImagesAtPublish} added \u2014 $remaining more required"
                        : "${_images.length}/${ProductFormState.maxImagesAtPublish} added \u2014 ready to publish",
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: canProceed
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),

                  _GrayOutlineButton(
                    icon: Icons.upload_outlined,
                    label: 'Upload Image',
                    onTap:
                        (_uploading ||
                            _images.length >=
                                ProductFormState.maxImagesAtPublish)
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                  const SizedBox(height: DesignTokens.s8),

                  _WhiteSolidButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Capture Image',
                    onTap:
                        (_uploading ||
                            _images.length >=
                                ProductFormState.maxImagesAtPublish)
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),

                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s16),
                    Wrap(
                      spacing: DesignTokens.s12,
                      runSpacing: DesignTokens.s12,
                      children: _images.asMap().entries.map((entry) {
                        return _ImageTile(
                          imageUrl: entry.value,
                          isPrimary: entry.key == _primaryIndex,
                          onSetPrimary: () => _setPrimary(entry.key),
                          onRemove: () => _removeImage(entry.key),
                        );
                      }).toList(),
                    ),
                  ],
                  if (_uploading) ...[
                    const SizedBox(height: DesignTokens.s12),
                    const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  ],

                  const SizedBox(height: DesignTokens.s20),
                  const Divider(color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s20),

                  const Text(
                    'Video Upload (Optional)',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  const Text(
                    'Add an externally hosted product video (max 60 sec)',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),

                  _GrayOutlineButton(
                    icon: Icons.link_rounded,
                    label: _video == null
                        ? 'Add Video Link'
                        : 'Replace Video Link',
                    onTap: _editVideo,
                  ),
                  if (_video != null) ...[
                    const SizedBox(height: DesignTokens.s8),
                    Row(
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          color: DesignTokens.primaryGreen,
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Expanded(
                          child: Text(
                            '${_video!.durationSeconds}s video attached',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _removeVideo,
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s24,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppFoundation,
            border: Border(
              top: BorderSide(color: DesignTokens.borderDefault),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: notifier.prevStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      foregroundColor: DesignTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 16),
                        SizedBox(width: DesignTokens.s8),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: canProceed ? _onProceed : null,
                    style: DesignTokens.primaryButtonStyle(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          canProceed
                              ? 'Proceed'
                              : 'Add $remaining more image${remaining == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: canProceed
                                ? DesignTokens.buttonPrimaryText
                                : DesignTokens.textMuted,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: canProceed
                              ? DesignTokens.buttonPrimaryText
                              : DesignTokens.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrayOutlineButton extends StatelessWidget {
  const _GrayOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27272A),
          side: const BorderSide(color: Color(0xFF3F3F46), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          foregroundColor: const Color(0xFFD4D4D8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFD4D4D8)),
            const SizedBox(width: DesignTokens.s8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4D4D8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteSolidButton extends StatelessWidget {
  const _WhiteSolidButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF52525C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 16,
              color: Color(0xFF52525C),
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Capture Image',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF52525C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.imageUrl,
    required this.isPrimary,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final String imageUrl;
  final bool isPrimary;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSetPrimary,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.s12),
          border: Border.all(
            color: isPrimary
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius - 2),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) =>
                    const Icon(Icons.image, color: DesignTokens.textMuted),
              ),
            ),
            if (isPrimary)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Primary',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textDark,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: const BoxDecoration(
                    color: DesignTokens.colorError,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
