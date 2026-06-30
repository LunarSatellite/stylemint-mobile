import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/creator_identity_providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
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
  late final TextEditingController _dobCtrl;
  late final TextEditingController _tiktokCtrl;

  String? _gender;
  DateTime? _dateOfBirth;
  bool _loaded = false;

  // Cached once from loadSuccess; persists through saving/saveFailure states.
  String _email = '';
  String _phone = '';
  String _avatarUrl = '';
  File? _localAvatarFile;

  // Preference toggles — UI only (no backend field yet).
  bool _sendPersonalized = false;
  bool _shareActivity = false;
  bool _includeBeta = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    Future.microtask(
      () => ref.read(pendingDeletionNotifierProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    _dobCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = profile.displayName;
    _bioCtrl.text = profile.bio;
    _websiteCtrl.text = profile.website;
    _gender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;
    _email = profile.email;
    _phone = profile.phone;
    _avatarUrl = profile.avatarUrl;
    if (profile.dateOfBirth != null) {
      final d = profile.dateOfBirth!;
      _dobCtrl.text =
          '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    }
  }

  // ── SAVE ─────────────────────────────────────────────────────────────────────
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    unawaited(
      ref.read(editProfileNotifierProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            gender: _gender,
            dateOfBirth: _dateOfBirth,
          ),
    );
  }

  // ── DATE PICKER ───────────────────────────────────────────────────────────────
  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.primaryGreen,
            onPrimary: DesignTokens.buttonPrimaryText,
            surface: DesignTokens.bgAppBody,
            onSurface: DesignTokens.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // ── AVATAR PICKER ─────────────────────────────────────────────────────────────
  void _showAvatarSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AvatarPickerSheet(
        onUploadFromPhotos: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.gallery);
        },
        onTakeAPicture: () async {
          Navigator.pop(context);
          await _pickImage(ImageSource.camera);
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _localAvatarFile = File(picked.path));
      // TODO: upload picked.path to blob storage → get URL → pass as avatarUrl
      // unawaited(ref.read(editProfileNotifierProvider.notifier).updateProfile(avatarUrl: uploadedUrl));
    }
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────────────────────────
  void _showDeleteSheet() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _DeleteAccountSheet(),
    ).then((reason) {
      if (reason != null && mounted) {
        unawaited(
          ref.read(deleteAccountNotifierProvider.notifier).deleteAccount(reason),
        );
      }
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileNotifierProvider);
    final deletionState = ref.watch(pendingDeletionNotifierProvider);
    final pendingRequest = deletionState.whenOrNull(found: (r) => r);

    ref.listen<PendingDeletionState>(pendingDeletionNotifierProvider, (_, next) {
      next.whenOrNull(
        cancelled: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deletion cancelled')),
          );
        },
        failure: (f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${f.toString()}')),
          );
        },
      );
    });

    ref.listen<EditProfileState>(editProfileNotifierProvider, (_, next) {
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

    ref.listen<DeleteAccountState>(deleteAccountNotifierProvider, (_, next) {
      next.whenOrNull(
        success: () => unawaited(
          ref.read(sessionControllerProvider.notifier).logout().then((_) {
            if (context.mounted) context.go(RouteNames.signInMethod);
          }),
        ),
        failure: (f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${f.toString()}')),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      // resizeToAvoidBottomInset defaults to true — keyboard shrinks the body
      // so SingleChildScrollView can always reach every field.
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile', style: DesignTokens.sectionInnerTitle),
        actions: [
          IconButton(
            icon: Icon(
              pendingRequest != null
                  ? Icons.cancel_outlined
                  : Icons.delete_outline,
              color: pendingRequest != null
                  ? DesignTokens.colorError
                  : DesignTokens.secondaryYellow,
            ),
            tooltip: pendingRequest != null
                ? 'Cancel deletion request'
                : 'Delete account',
            onPressed: pendingRequest != null
                ? () => ref
                    .read(pendingDeletionNotifierProvider.notifier)
                    .cancel(pendingRequest.id)
                : _showDeleteSheet,
          ),
        ],
      ),
      body: state.when(
        initial: _loadingBody,
        loadInProgress: _loadingBody,
        loadFailure: (f) => Center(
          child: Text(
            'Failed to load: ${f.toString()}',
            style: DesignTokens.smallRegular,
          ),
        ),
        loadSuccess: (profile) {
          _populateFields(profile);
          _avatarUrl = profile.avatarUrl;
          return _buildForm(saving: false, pendingRequest: pendingRequest);
        },
        saving: () => _buildForm(saving: true, pendingRequest: pendingRequest),
        saveSuccess: (profile) {
          _populateFields(profile);
          _avatarUrl = profile.avatarUrl;
          return _buildForm(saving: false, pendingRequest: pendingRequest);
        },
        saveFailure: (_) => _buildForm(saving: false, pendingRequest: pendingRequest),
      ),
    );
  }

  Widget _loadingBody() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );

  // ── FORM ──────────────────────────────────────────────────────────────────────
  Widget _buildForm({required bool saving, DeletionRequest? pendingRequest}) {
    // SafeArea(top:false) handles the home indicator / navigation bar at the
    // bottom without duplicating the AppBar's top safe-area inset.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignTokens.s20),

              // Avatar ─────────────────────────────────────────────────────────
              _AvatarSection(
                avatarUrl: _avatarUrl,
                localFile: _localAvatarFile,
                onTap: _showAvatarSheet,
              ),
              const SizedBox(height: DesignTokens.s24),

              // Creator-only handle + specializations card (hidden for customers)
              const _CreatorIdentitySection(),

              // ── Personal Information ─────────────────────────────────────────
              const _SectionHeader('Personal Information'),
              const SizedBox(height: DesignTokens.s12),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                style: _kInputStyle,
                decoration: DesignTokens.inputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: DesignTokens.s12),
              _ReadOnlyField(label: 'Email Address', value: _email),
              const SizedBox(height: DesignTokens.s12),
              _ReadOnlyField(label: 'Phone No.', value: _phone),
              const SizedBox(height: DesignTokens.s24),

              // ── Optional Information ─────────────────────────────────────────
              const _SectionHeader('Optional Information'),
              const SizedBox(height: DesignTokens.s12),

              // Date of Birth — taps open a date picker dialog
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                style: _kInputStyle,
                decoration: DesignTokens.inputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: DesignTokens.inputFieldDropdownIcon,
                  ),
                ),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: DesignTokens.s6),
              _HintRow('For personalized birthday offers'),
              const SizedBox(height: DesignTokens.s12),

              // Gender — rendered identically to other TextFormFields
              _GenderSelector(
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: DesignTokens.s12),

              // Bio / About Me — multiline with live char counter
              TextFormField(
                controller: _bioCtrl,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    const SizedBox.shrink(),
                style: _kInputStyle,
                decoration: DesignTokens.inputDecoration(labelText: 'Bio/About Me'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: DesignTokens.s6),
              _HintRow('${_bioCtrl.text.length}/500 Characters'),
              const SizedBox(height: DesignTokens.s24),

              // ── Social Links ─────────────────────────────────────────────────
              const _SectionHeader('Social Links'),
              const SizedBox(height: DesignTokens.s12),
              _SocialField(
                controller: _websiteCtrl,
                label: 'Instagram',
                hint: 'instagram.com/username',
                prefixIcon: const _InstagramIcon(),
              ),
              const SizedBox(height: DesignTokens.s12),
              _SocialField(
                controller: _tiktokCtrl,
                label: 'Tiktok',
                hint: 'tiktok.com/@username',
                prefixIcon: const _TiktokIcon(),
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Preferences ──────────────────────────────────────────────────
              const _SectionHeader('Preferences'),
              const SizedBox(height: DesignTokens.s12),
              _CheckboxItem(
                value: _sendPersonalized,
                label: 'Send me personalized product recommendations',
                onChanged: (v) => setState(() => _sendPersonalized = v ?? false),
              ),
              _CheckboxItem(
                value: _shareActivity,
                label: 'Share my activity with creators I follow',
                onChanged: (v) => setState(() => _shareActivity = v ?? false),
              ),
              _CheckboxItem(
                value: _includeBeta,
                label: 'Include me in beta testing programs',
                onChanged: (v) => setState(() => _includeBeta = v ?? false),
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Delete Account row ───────────────────────────────────────────
              _DeleteAccountRow(
                isPending: pendingRequest != null,
                onTap: pendingRequest != null
                    ? () => ref
                        .read(pendingDeletionNotifierProvider.notifier)
                        .cancel(pendingRequest.id)
                    : _showDeleteSheet,
              ),
              const SizedBox(height: DesignTokens.s24),

              // ── Save Changes ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: DesignTokens.primaryButtonStyle(),
                  child: saving
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

  static const _kInputStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    color: DesignTokens.textWhite,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR SECTION
// Shows a local file (just picked) or a cached network URL.
// Yellow gradient ring + camera chip indicate it is tappable.
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.localFile,
    required this.onTap,
  });

  final String avatarUrl;
  final File? localFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = localFile != null
        ? FileImage(localFile!)
        : avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(avatarUrl)
            : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yellow gradient ring
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF1C40F), Color(0xFFF39C12), Color(0xFFE67E22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: DesignTokens.bgAppBodyLight,
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person, color: DesignTokens.iconLight, size: 36)
                  : null,
            ),
          ),
          // Camera chip
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignTokens.bgAppFoundation,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 12,
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.onUploadFromPhotos,
    required this.onTakeAPicture,
  });

  final VoidCallback onUploadFromPhotos;
  final VoidCallback onTakeAPicture;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _SheetRow(
            icon: Icons.image_outlined,
            label: 'Upload from photos',
            onTap: onUploadFromPhotos,
          ),
          Divider(height: 1, color: DesignTokens.borderDefault),
          _SheetRow(
            icon: Icons.camera_alt_outlined,
            label: 'Take a picture',
            onTap: onTakeAPicture,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: DesignTokens.textLight, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.iconLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE ACCOUNT ROW  (inline, inside the form)
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteAccountRow extends StatelessWidget {
  const _DeleteAccountRow({required this.onTap, this.isPending = false});

  final VoidCallback onTap;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    const color = DesignTokens.colorError;
    final label = isPending ? 'Cancel Deletion Request' : 'Delete Account';
    final icon = isPending ? Icons.cancel_outlined : Icons.delete_outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1C0A0A),
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: const Color(0xFF3D1515)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(color: color),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE ACCOUNT SHEET  (modal bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
// Pops with the selected reason string, or null if cancelled.
class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  static const _reasons = [
    'I no longer use this app',
    'Privacy concerns',
    'Found a better alternative',
    'Too many notifications',
    'Other',
  ];

  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  center: Alignment.topCenter,
                  radius: 1.2,
                ),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),

            Text(
              'Delete Account',
              style: DesignTokens.sectionInnerTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please tell us why you\'re leaving. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // Reason picker
            ...List.generate(_reasons.length, (i) {
              final r = _reasons[i];
              final selected = _selectedReason == r;
              return InkWell(
                onTap: () => setState(() => _selectedReason = r),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.colorError.withValues(alpha: 0.12)
                        : DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.colorError
                          : DesignTokens.borderDefault,
                    ),
                  ),
                  child: Text(
                    r,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: selected
                          ? DesignTokens.colorError
                          : DesignTokens.textLight,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.colorError,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                onPressed: _selectedReason == null
                    ? null
                    : () => Navigator.pop(context, _selectedReason),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: DesignTokens.mediumSemibold);
}

/// Bullet + small muted text — used for "For personalized birthday offers"
/// and the bio character counter.
class _HintRow extends StatelessWidget {
  const _HintRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: DesignTokens.textMuted),
        const SizedBox(width: 6),
        Text(text, style: DesignTokens.smallRegular),
      ],
    );
  }
}

/// Read-only TextFormField (email, phone). Muted text makes it visually
/// distinct from editable fields without a different border.
class _ReadOnlyField extends StatefulWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_ReadOnlyField> createState() => _ReadOnlyFieldState();
}

class _ReadOnlyFieldState extends State<_ReadOnlyField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ReadOnlyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      readOnly: true,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.textMuted,
      ),
      decoration: DesignTokens.inputDecoration(labelText: widget.label),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENDER SELECTOR
// Uses DropdownButtonFormField with DesignTokens.inputDecoration() so it is
// visually identical to every other TextFormField on this screen — same fill
// (#27272A), border (#52525C → green on focus), corner radius (8 px), and
// label behaviour.  No outer Container needed (that was causing a double-border).
// ─────────────────────────────────────────────────────────────────────────────
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _items = <DropdownMenuItem<String?>>[
    DropdownMenuItem(value: null, child: Text('Prefer not to say')),
    DropdownMenuItem(value: 'male', child: Text('Male')),
    DropdownMenuItem(value: 'female', child: Text('Female')),
    DropdownMenuItem(value: 'other', child: Text('Other')),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      dropdownColor: DesignTokens.bgAppBody,
      menuMaxHeight: 240,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: DesignTokens.inputFieldDropdownIcon,
      ),
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.textWhite,
      ),
      // Uses the same inputDecoration helper as every other field.
      decoration: DesignTokens.inputDecoration(labelText: 'Gender'),
      items: _items,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL FIELD
// Label text above + TextFormField with brand icon prefix.
// ─────────────────────────────────────────────────────────────────────────────
class _SocialField extends StatelessWidget {
  const _SocialField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textLight),
        ),
        const SizedBox(height: DesignTokens.s8),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.url,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textWhite,
          ),
          decoration: DesignTokens.inputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              child: prefixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKBOX ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _CheckboxItem extends StatelessWidget {
  const _CheckboxItem({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              checkColor: DesignTokens.buttonPrimaryText,
              activeColor: DesignTokens.primaryGreen,
              side: const BorderSide(
                color: DesignTokens.inputFieldBorder,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL ICONS
// ─────────────────────────────────────────────────────────────────────────────
class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(bounds),
      child: const Icon(Icons.photo_camera_outlined, size: 20, color: Colors.white),
    );
  }
}

class _TiktokIcon extends StatelessWidget {
  const _TiktokIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.music_note_outlined, size: 20, color: Color(0xFF00F2EA));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATOR IDENTITY SECTION  (hidden for non-creators)
// ─────────────────────────────────────────────────────────────────────────────
class _CreatorIdentitySection extends ConsumerWidget {
  const _CreatorIdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreator = ref.watch(isCreatorProvider).maybeWhen<bool>(
      data: (v) => v,
      orElse: () => false,
    );
    if (!isCreator) return const SizedBox.shrink();

    final handle = ref.watch(activeHandleProvider);
    final specs = ref.watch(creatorSpecializationsProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: DesignTokens.s16),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator handle',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    handle.when(
                      loading: () =>
                          Text('…', style: DesignTokens.oneLinerSemibold),
                      error: (_, __) =>
                          Text('—', style: DesignTokens.oneLinerSemibold),
                      data: (h) => Text(
                        (h == null || h.isEmpty) ? '—' : '@$h',
                        style: DesignTokens.oneLinerSemibold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push(RouteNames.handleSetup),
                child: Text(
                  'Change',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.primaryGreen),
                ),
              ),
            ],
          ),
          specs.maybeWhen(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.s12),
                    child: Wrap(
                      spacing: DesignTokens.s8,
                      runSpacing: DesignTokens.s8,
                      children: list
                          .map((s) => _SpecChip(label: s))
                          .toList(growable: false),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}
