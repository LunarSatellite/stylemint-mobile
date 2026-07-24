import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → Products → ⋮ → Edit Product Details — currently images-only
/// (see `AddProductNotifier.loadExistingImages`/`saveImagesOnly`): the
/// backend's wizard PATCH endpoints are Draft-only by design, so a
/// dedicated `PATCH .../images` endpoint was added instead of re-opening
/// the full 5-step wizard on an already-published product.
class EditProductImagesScreen extends ConsumerStatefulWidget {
  const EditProductImagesScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<EditProductImagesScreen> createState() =>
      _EditProductImagesScreenState();
}

class _EditProductImagesScreenState
    extends ConsumerState<EditProductImagesScreen> {
  final List<String> _images = [];
  int _primaryIndex = 0;
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .loadExistingImages(widget.productId);
    if (!mounted) return;
    final formState = ref.read(addProductNotifierProvider).maybeWhen(
          loadSuccess: (fs) => fs,
          orElse: () => null,
        );
    setState(() {
      _loading = false;
      _loadFailed = !ok;
      if (ok && formState?.step2 != null) {
        _images
          ..clear()
          ..addAll(formState!.step2!.images);
        _primaryIndex = formState.step2!.primaryImageIndex;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= ImagesInfo.maxImages) return;
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
    if (!mounted) return;
    final formState = ref.read(addProductNotifierProvider).maybeWhen(
          loadSuccess: (fs) => fs,
          orElse: () => null,
        );
    setState(() {
      _uploading = false;
      if (formState?.step2 != null) {
        _images
          ..clear()
          ..addAll(formState!.step2!.images);
        _primaryIndex = formState.step2!.primaryImageIndex;
      }
    });
  }

  void _removeImage(int index) {
    if (index < _primaryIndex) {
      _primaryIndex--;
    } else if (index == _primaryIndex && _images.length > 1) {
      _primaryIndex = 0;
    }
    setState(() => _images.removeAt(index));
  }

  void _setPrimary(int index) => setState(() => _primaryIndex = index);

  Future<void> _save() async {
    if (_images.length < ImagesInfo.minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add at least ${ImagesInfo.minImages} images before saving.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    // Sync the notifier's step2 with any local edits (remove/reorder-
    // primary) before persisting — uploadImage already kept it in sync for
    // additions, but removal/primary changes only touch local state above.
    ref.read(addProductNotifierProvider.notifier).updateImages(
          ImagesInfo(images: List.from(_images), primaryImageIndex: _primaryIndex),
        );
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .saveImagesOnly(widget.productId);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Images updated!' : 'Failed to update images.'),
        backgroundColor: ok ? DesignTokens.primaryGreen : DesignTokens.colorError,
      ),
    );
    if (ok) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Product Images',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
            )
          : _loadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to load product images.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
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
                              Text(
                                '${_images.length}/${ImagesInfo.minImages} minimum'
                                '${_images.length < ImagesInfo.minImages ? ' — add ${ImagesInfo.minImages - _images.length} more' : ''}',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _images.length < ImagesInfo.minImages
                                      ? DesignTokens.colorError
                                      : DesignTokens.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.s12),
                              _OutlineButton(
                                icon: Icons.upload_outlined,
                                label: 'Upload Image',
                                onTap: _uploading ||
                                        _images.length >= ImagesInfo.maxImages
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                              ),
                              const SizedBox(height: DesignTokens.s8),
                              _SolidButton(
                                icon: Icons.photo_camera_outlined,
                                label: 'Capture Image',
                                onTap: _uploading ||
                                        _images.length >= ImagesInfo.maxImages
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                              ),
                              if (_images.isNotEmpty) ...[
                                const SizedBox(height: DesignTokens.s16),
                                Wrap(
                                  spacing: DesignTokens.s12,
                                  runSpacing: DesignTokens.s12,
                                  children: _images.asMap().entries.map((e) {
                                    return _ImageTile(
                                      imageUrl: e.value,
                                      isPrimary: e.key == _primaryIndex,
                                      onSetPrimary: () => _setPrimary(e.key),
                                      onRemove: () => _removeImage(e.key),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DesignTokens.s16,
                          DesignTokens.s12,
                          DesignTokens.s16,
                          DesignTokens.s16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: DesignTokens.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: DesignTokens.primaryButtonStyle(),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    'Save Images',
                                    style: DesignTokens.mediumSemibold.copyWith(
                                      color: DesignTokens.buttonPrimaryText,
                                    ),
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

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
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
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF71717B)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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

class _SolidButton extends StatelessWidget {
  const _SolidButton({
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF52525C)),
            const SizedBox(width: DesignTokens.s8),
            Text(
              label,
              style: const TextStyle(
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
            color: isPrimary ? DesignTokens.primaryGreen : DesignTokens.borderDefault,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
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
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
