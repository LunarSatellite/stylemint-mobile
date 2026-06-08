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
  ConsumerState<Step2ImagesScreen> createState() =>
      _Step2ImagesScreenState();
}

class _Step2ImagesScreenState extends ConsumerState<Step2ImagesScreen> {
  final List<String> _images = [];
  int _primaryIndex = 0;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(addProductNotifierProvider);
      state.maybeWhen(
        loadSuccess: (fs) {
          if (fs.step2 != null) {
            setState(() {
              _images.addAll(fs.step2!.images);
              _primaryIndex = fs.step2!.primaryImageIndex;
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
            _images.clear();
            _images.addAll(fs.step2!.images);
            _primaryIndex = fs.step2!.primaryImageIndex;
            _uploading = false;
          });
        }
      },
      loadFailure: (_, __) {
        setState(() => _uploading = false);
      },
      orElse: () {},
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _uploading = true);
    ref.read(addProductNotifierProvider.notifier).uploadImage(picked.path);
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
    final info = ImagesInfo(
      images: List.from(_images),
      primaryImageIndex: _primaryIndex,
    );
    ref.read(addProductNotifierProvider.notifier).updateImages(info);
  }

  void _onNext() {
    _emitUpdate();
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddProductState>(addProductNotifierProvider, (prev, next) {
      _syncFromState(next);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Images & Media',
              style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Upload 5-10 images (max 5mb each in JPG/PNG)',
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight),
          ),
          const SizedBox(height: DesignTokens.s16),
          // Spec: Upload Image + Capture Image (white solid, #52525C text).
          Row(
            children: [
              Expanded(
                child: _MediaButton(
                  icon: Icons.upload_outlined,
                  label: 'Upload Image',
                  onTap: _uploading ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _MediaButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Capture Image',
                  onTap: _uploading ? null : () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
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
                  color: DesignTokens.primaryGreen, strokeWidth: 2),
            ),
          ],
          const SizedBox(height: DesignTokens.s24),
          // Optional product video (local/MOCK — ImagesInfo has no video field).
          Text('Optional', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          GestureDetector(
            onTap: () {/* TODO(vendor): video upload (no video field yet). */},
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.s12),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined,
                      size: 24, color: DesignTokens.iconLight),
                  const SizedBox(width: DesignTokens.s12),
                  Text('Upload product video (max 60 sec)',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: _images.isEmpty ? null : _onNext,
              style: DesignTokens.primaryButtonStyle(),
              child: Text(
                'Next',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Spec: white solid button, #52525C text, 999 radius, 16px leading icon.
class _MediaButton extends StatelessWidget {
  const _MediaButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: DesignTokens.textWhite,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF52525C)),
              const SizedBox(width: DesignTokens.s8),
              Text(label,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF52525C),
                  )),
            ],
          ),
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
            color:
                isPrimary ? DesignTokens.primaryGreen : DesignTokens.borderDefault,
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
                errorBuilder: (_, __, ___) => const Icon(Icons.image,
                    color: DesignTokens.textMuted),
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
                  child: Text('Primary',
                      style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textDark)),
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
