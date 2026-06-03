import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _websiteCtrl;
  String? _gender;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
  }

  void _populateFields(String displayName, String bio, String website, String? gender) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = displayName;
    _bioCtrl.text = bio;
    _websiteCtrl.text = website;
    _gender = gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(editProfileNotifierProvider.notifier).updateProfile(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      gender: _gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileNotifierProvider);

    ref.listen<EditProfileState>(editProfileNotifierProvider, (prev, next) {
      next.whenOrNull(
        saveSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')),
          );
          context.pop(true);
        },
        saveFailure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: ${failure.toString()}')),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loadingBody,
        loadInProgress: _loadingBody,
        loadFailure: (failure) => Center(
          child: Text('Failed to load: ${failure.toString()}', style: DesignTokens.smallRegular),
        ),
        loadSuccess: (profile) {
          _populateFields(profile.displayName, profile.bio, profile.website, profile.gender);
          return _buildForm(profile);
        },
        saving: () => _buildForm(null, saving: true),
        saveSuccess: (profile) => _buildForm(profile),
        saveFailure: (failure) => _buildForm(null),
      ),
    );
  }

  Widget _loadingBody() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _buildForm(dynamic profile, {bool saving = false}) {
    final avatarUrl = profile is EditProfileState ? profile.maybeWhen(
      loadSuccess: (p) => p.avatarUrl,
      saveSuccess: (p) => p.avatarUrl,
      orElse: () => '',
    ) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: DesignTokens.s12),
            GestureDetector(
              onTap: () {
                // TODO: image picker for avatar
              },
              child: Stack(
                children: [
                  // Spec: 72x72 avatar (radius 36).
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, color: DesignTokens.iconLight, size: 32)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    // Spec: 20x20 chip, #F4F4F5 fill, 1px #D4D4D8 border, 12px
                    // radius, 14x14 #52525C icon.
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4D4D8)),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Color(0xFF52525C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(labelText: 'Bio/About Me'),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextFormField(
              controller: _websiteCtrl,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(labelText: 'Website'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: DesignTokens.s16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.inputFieldFill,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                border: Border.all(color: DesignTokens.inputFieldBorder),
              ),
              child: DropdownButtonFormField<String>(
                value: _gender,
                dropdownColor: DesignTokens.bgAppBody,
                style: const TextStyle(color: DesignTokens.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(value: null, child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
            ),
            const SizedBox(height: DesignTokens.s32),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  saving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
